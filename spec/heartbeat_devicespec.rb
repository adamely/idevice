require_relative 'spec_helper'

describe Idev::HeartbeatClient do
  before :all do
    @hb = Idev::HeartbeatClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @hb.should be_a Idev::HeartbeatClient
  end

  it "should send and receive a heartbeat" do
    pending "Heartbeat is not working on my test device"
    marco = @hb.receive_plist
    marco.should be_a Hash
    @hb.send_plist("Command" => "Polo").should be_true
  end
end

