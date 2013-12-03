require_relative 'spec_helper'

describe Idevice::RestoreClient do
  before :each do
    @rc = Idevice::RestoreClient.attach(idevice:shared_idevice)
  end

  before :each do
    @rc.goodbye rescue nil
  end

  it "should attach" do
    @rc.should be_a Idevice::RestoreClient
  end

  it "should set the client label" do
    @rc.set_label("idev-unit-tests")
  end

  it "should start a restore" 

  it "should get the query type of the service daemon" do
    pending "getting PLIST_ERROR on iOS 7.x"
    res = @rc.query_type
  end

  it "should 'query' a value from the device specified by a key" do
    pending "getting PLIST_ERROR on iOS 7.x"
    res = @rc.query_value "foo"
  end

  it "should 'get' a value from information plist based by a key" do
    pending "getting NOT_ENOUGH_DATA on iOS 7.x"
    res = @rc.get_value "foo"
  end

  it "should request a device reboot" do
    pending "don't actually reboot"
    pending "getting PLIST_ERROR on iOS 7.x"
    @rc.reboot.should be_true
  end

  it "should say goodbye" do
    pending "getting PLIST_ERROR on iOS 7.x"
    @rc.goodbye.should be_true
  end

  it "should send a plist"

  it "should receive a plist"

end
