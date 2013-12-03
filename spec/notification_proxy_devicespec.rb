require_relative 'spec_helper'

describe Idevice::NotificationProxyClient do
  before :each do
    @sync = Idevice::NPClient.attach(idevice:shared_idevice)
  end

  after :each do
  end

  it "should attach" do
    @sync.should be_a Idevice::NotificationProxyClient
  end

  it "should post a notification"

  it "should observe a notification"

  it "should observe notifications (in the plural)"

  it "should set a notification callback"

  it "should receive notifications via a callback"

end
