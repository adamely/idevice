require 'spec_helper'

describe Idev::MobileBackup2Client do
  before :all do
    @idevice = Idev::Idevice.attach
  end

  before :each do
    @mb2 = Idev::MobileBackup2Client.attach(idevice:@idevice)
  end

  after :each do
  end

  it "should attach" do
    @mb2.should be_a Idev::MobileBackup2Client
  end

  it "needs functional tests" do
    pending "writing more specs for MobileBackup2Client"
  end
end


