require 'spec_helper'

describe Idev::FileRelayClient do
  before :each do
    @frc = Idev::FileRelayClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @frc.should be_a Idev::FileRelayClient
  end

  it "should return an error when requesting invalid sources" do
    lambda{ @frc.request_sources("this source is lies") }.should raise_error(Idev::FileRelayError)
  end

  it "should return an error when requesting invalid sources"
end

