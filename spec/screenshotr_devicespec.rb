require_relative 'spec_helper'

describe Idev::ScreenShotrClient do
  before :each do
    pending "needs developer disk mounted" unless ENV["DEVTESTS"]
    @ss = Idev::ScreenShotrClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @ss.should be_a Idev::ScreenShotrClient
  end

  it "should take a screenshot" do
    data = @ss.take_screenshot
    data.should be_a String
    shell_pipe(data[0..256], "file -").should =~ /image data/
  end
end

