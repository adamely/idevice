require 'spec_helper'

if ENV["TEST_MOBILEBACKUP1"]

  describe Idev::MobileBackupClient do
    before :all do
      @idevice = Idev::Idevice.attach
    end

    before :each do
      @mb = Idev::MobileBackupClient.attach(idevice:@idevice)
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
