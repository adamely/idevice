require_relative 'spec_helper'

if ENV["TEST_MOBILEBACKUP1"]

  describe Idev::MobileBackupClient do
    before :each do
      @mb = Idev::MobileBackupClient.attach(idevice:shared_idevice)
    end

    after :each do
    end

    it "should attach" do
      @mb.should be_a Idev::MobileBackupClient
    end

    it "needs functional tests" do
      pending "writing more specs for MobileBackupClient"
    end
  end
end
