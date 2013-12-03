require_relative 'spec_helper'

describe Idevice::ImageMounterClient do
  before :each do
    @imgmounter = Idevice::ImageMounterClient.attach(idevice:shared_idevice)
  end

  after :each do
    @imgmounter.hangup rescue nil
  end

  it "should attach" do
    @imgmounter.should be_a Idevice::ImageMounterClient
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
    lambda{ @imgmounter.lookup_image }.should raise_error(Idevice::ImageMounterError)
  end

  it "should mount an image"
end

