require_relative 'spec_helper'

describe Idev::ImageMounterClient do

  before :all do
    @idevice = Idev::Idevice.attach
  end

  before :each do
    @imgmounter = Idev::ImageMounterClient.attach(idevice:@idevice)
  end

  after :each do
    @imgmounter.hangup rescue nil
  end

  it "should look up whether the Developer image is mounted" do
    res=@imgmounter.lookup_image("Developer")
    res["Status"].should == "Complete"
    res.should have_key "ImagePresent"
  end

  it "should look up whether the Developer image is mounted (by default)" do
    res=@imgmounter.lookup_image
    res["Status"].should == "Complete"
    res.should have_key "ImagePresent"
  end

  it "should look up whether the Debug image is mounted" do
    res=@imgmounter.lookup_image("Debug")
    res["Status"].should == "Complete"
    res.should have_key "ImagePresent"
  end

  it "should look up whether an arbitrary image is mounted" do
    @imgmounter.lookup_image("SomebogusImageName").should == {"ImagePresent"=>false, "Status"=>"Complete"}
  end

  it "should hangup" do
    @imgmounter.hangup.should be_true
    lambda{ @imgmounter.lookup_image }.should raise_error(Idev::ImageMounterError)
  end

  it "should mount an image"
end

