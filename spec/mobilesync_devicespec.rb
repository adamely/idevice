require 'spec_helper'

describe Idev::MobileBackupClient do
  before :each do
    @sync = Idev::MobileSyncClient.attach(idevice:shared_idevice)
  end

  after :each do
  end

  it "should attach" do
    @sync.should be_a Idev::MobileSyncClient
  end

  it "needs functional tests" do
    pending "writing more specs for MobileSyncClient"
  end
end
