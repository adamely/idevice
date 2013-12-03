require_relative 'spec_helper'

describe Idevice::WebInspectorClient do
  before :each do
    @wic = Idevice::WebInspectorClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @wic.should be_a Idevice::WebInspectorClient
  end

  it "should send a plist"

  it "should receive a plist"
end

