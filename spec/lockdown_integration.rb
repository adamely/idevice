require_relative 'spec_helper'

describe Idev::LockdownClient do
  it "should attach without arguments" do
    client = Idev::LockdownClient.attach
    client.should be_a Idev::LockdownClient
    client.device_udid.should == client.get_value(nil, "UniqueDeviceID")
  end

  it "should attach with an instantiated idevice" do
    client = Idev::LockdownClient.attach(idevice: Idev::Idevice.attach)
    client.should be_a Idev::LockdownClient
    client.device_udid.should == client.get_value(nil, "UniqueDeviceID")
  end

  context "an attached client" do
    before :all do
      @idevice = Idev::Idevice.attach
    end

    before :each do
      @lockdown = Idev::LockdownClient.attach(idevice: @idevice)
    end

    it "should list sync data classes" do
      result = @lockdown.sync_data_classes
      result.should be_a Array
      result.count.should > 1
    end

    it "should query type" do
      @lockdown.query_type.should == "com.apple.mobile.lockdown"
    end

    it "should have a device_udid" do
      result = @lockdown.device_udid
      result.should be_a String
      result.should =~ /^[a-f0-9]{40}$/i
      result.should == @lockdown.get_value(nil, "UniqueDeviceID")
    end

    it "should have a device_name" do
      result = @lockdown.device_name
      result.should be_a String
      result.should == @lockdown.get_value(nil, "DeviceName")
    end

    it "should get a value for nil:UniqueDeviceID" do
      result = @lockdown.get_value(nil, "UniqueDeviceID")
      result.should be_a String
      result.should =~ /^[a-f0-9]{40}$/i
      result.should == @lockdown.device_udid
    end

    it "should not get a value for nil:BogusKey" do
      result = @lockdown.get_value(nil, "BogusKey")
      result.should be_nil
    end

    it "should get an empty hash for BogusDomain" do
      result = @lockdown.get_value("BogusDomain", nil)
      result.should == {}
    end

    it "should not get a value for BogusDomain:UniqueDeviceID" do
      result = @lockdown.get_value("BogusDomain", "UniqueDeviceID")
      result.should be_nil
    end

    it "should start an 'afc' lockdown service" do
      ldsvc = @lockdown.start_service("com.apple.afc")
      ldsvc.should_not be_nil
      ldsvc[:port].should > 1024
      [0,1].include?(ldsvc[:ssl_enabled]).should be_true
    end

    it "should raise an error starting a nonexistent lockdown service" do
      lambda{ @lockdown.start_service("nonexistent.service.garbage") }.should raise_error Idev::IdeviceLibError
    end

  end
end
