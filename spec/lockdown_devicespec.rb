#
# Copyright (c) 2013 Eric Monti
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require_relative 'spec_helper'

describe Idevice::LockdownClient do
  it "should attach without arguments" do
    client = Idevice::LockdownClient.attach
    client.should be_a Idevice::LockdownClient
    client.device_udid.should == client.get_value(nil, "UniqueDeviceID")
  end

  it "should attach with an instantiated idevice" do
    client = Idevice::LockdownClient.attach(idevice: Idevice::Idevice.attach)
    client.should be_a Idevice::LockdownClient
    client.device_udid.should == client.get_value(nil, "UniqueDeviceID")
  end

  context "an attached client" do
    before :each do
      @lockdown = Idevice::LockdownClient.attach(idevice: shared_idevice)
    end

    after :each do
      @lockdown.goodbye
    end

    it "should attach" do
      @lockdown.should be_a Idevice::LockdownClient
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
      lambda{ @lockdown.start_service("nonexistent.service.garbage") }.should raise_error Idevice::IdeviceLibError
    end

  end
end
