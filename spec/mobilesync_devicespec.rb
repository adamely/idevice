require_relative 'spec_helper'

describe Idevice::MobileSyncClient do
  before :each do
    @sync = Idevice::MobileSyncClient.attach(idevice:shared_idevice)
  end

  after :each do
  end

  it "should attach" do
    @sync.should be_a Idevice::MobileSyncClient
  end

  it "should send a plist"

  it "should receive a plist"

  it "should start synchronizing a data class with the device"

  it "should cancel"

  it "should finish"

  it "should get all records from a device"

  it "should get changes from a device"

  it "should clear all records on a device"

  it "should receive changes from a device"

  it "should acknowledge changes from a device"

  it "should signal it is ready to send changes from the computer"

  it "should send changes"

  it "should remap identifiers"


end
