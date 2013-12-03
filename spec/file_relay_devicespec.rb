require 'spec_helper'

describe Idevice::FileRelayClient do
  before :each do
    @frc = Idevice::FileRelayClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @frc.should be_a Idevice::FileRelayClient
  end

  it "should return an error when requesting invalid sources" do
    lambda{ @frc.request_sources("this source is lies") }.should raise_error(Idevice::FileRelayError)
  end

  it "should request and receive CrashReporter logs" do
    crashdata = @frc.request_sources("CrashReporter")
    crashdata.should be_a String

    # the returned data is actually a gzip-compressed cpio
    shell_pipe(crashdata[0..256], "file -").should =~ /gzip compressed data, from Unix\n$/
    shell_pipe(crashdata, "cpio -t").should =~ /^\.\/var\/mobile\/Library/
  end
end

