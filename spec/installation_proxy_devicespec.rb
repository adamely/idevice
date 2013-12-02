require_relative 'spec_helper'

describe Idev::InstProxyClient do
  before :each do
    @instproxy = Idev::InstProxyClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @instproxy.should be_a Idev::InstProxyClient
  end

  it "should browse installed apps" do
    browsedata = @instproxy.browse()
    browsedata.should be_a Array
    browsedata.map{|x| x.class }.uniq.should == [Hash]
    browsedata.map{|x| x["ApplicationType"]}.should include "System"
  end

  it "should install an application"

  it "should upgrade an application"

  it "should uninstall an application"

  it "should lookup archives"

  it "should archive an application"

  it "should restore an archived application"

  it "should remove an archive"

end

