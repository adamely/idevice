require_relative 'spec_helper'

describe Idev::AFC do
  before :all do
    @idevice = Idev::Idevice.attach
  end

  before :each do
    @afc = Idev::AFC.attach(idevice:@idevice)
  end

  it "should return device info" do
    result = @afc.device_info
    result.should be_a Hash
    result.keys.sort.should == ["FSBlockSize", "FSFreeBytes", "FSTotalBytes", "Model"]
    result["FSBlockSize"].should =~ /^\d+$/
    result["FSFreeBytes"].should =~ /^\d+$/
    result["FSTotalBytes"].should =~ /^\d+$/
    result["FSTotalBytes"].to_i.should > result["FSFreeBytes"].to_i
  end

  it "should return device info for specific keys" do
    totbytes = @afc.device_info("FSTotalBytes")
    totbytes.should be_a String
    totbytes.should =~ /^\d+$/

    freebytes = @afc.device_info("FSFreeBytes")
    freebytes.should be_a String
    freebytes.should =~ /^\d+$/

    totbytes.to_i.should > freebytes.to_i
  end

  it "should list directory contents" do
    result = @afc.read_directory('/')
    result.should be_a Array
    result[0,2].should == ['.', '..']
  end

  it "should raise an error listing an invalid directory" do
    lambda{ @afc.read_directory('/TOTALLYNOTREALLYTHERE') }.should raise_error(Idev::IdeviceLibError)
  end

  it "should get file information" do
    result = @afc.file_info('/')
    result.should be_a Hash
    result.keys.sort.should == ["st_birthtime", "st_blocks", "st_ifmt", "st_mtime", "st_nlink", "st_size"]
    result["st_ifmt"].should == "S_IFDIR"
  end

  it "should raise an error getting info for an invalid path" do
    lambda{ @afc.file_info('/TOTALLYNOTREALLYTHERE') }.should raise_error(Idev::IdeviceLibError)
  end

  it "should remove a file path"

  it "should remove an (empty) directory path"

  it "should rename a file path"

  it "should rename a directory path"

  it "should truncate a file path"

  it "should make a directory"

  it "should make a link"

  it "should set file time"
end
