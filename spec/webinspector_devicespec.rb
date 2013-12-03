require_relative 'spec_helper'

describe Idev::WebInspectorClient do
  before :each do
    @wic = Idev::WebInspectorClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @wic.should be_a Idev::WebInspectorClient
  end

  it "should send a plist"

  it "should receive a plist"
end

