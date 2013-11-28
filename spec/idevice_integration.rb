require_relative 'spec_helper'

describe Idev::Idevice do

  it "should not be usable after being destroyed" do
    dev = Idev::Idevice.new
    dev.destroy
    lambda{ dev.udid }.should raise_error
    lambda{ dev.destroy }.should raise_error
  end

  context "with a connected device" do
    before :all do
      @idevice = Idev::Idevice.new
    end

    after :all do
      if @idevice
        @idevice.destroy
      end
    end

    it "should have a udid" do
      @idevice.udid.should_not be_nil
      @idevice.udid.should =~ /^[a-f0-9]{40}$/i
    end

    it "should have a handle" do
      @idevice.handle.should_not be_nil
      @idevice.handle.should be_a Numeric
    end

    it "should be ready" do
      @idevice.should be_ready
    end

    it "should not be destroyed" do
      @idevice.should_not be_destroyed
    end

    it "should not be connected at first" do
      @idevice.should_not be_connected
      @idevice.should be_disconnected
    end

    it "should connect to the lockdownd port" do
      begin
        @idevice.connect(62078).should be_true
        @idevice.should be_connected
        @idevice.should_not be_disconnected

      ensure
        @idevice.disconnect if @idevice.connected?
      end
    end

    it "should handshake with lockdownd" do
      begin
        @idevice.connect(62078).should be_true
        @idevice.should be_connected
        @idevice.should_not be_disconnected

        @idevice.send_data("\000\000\001\032<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>Label</key>\n\t<string>afcclient</string>\n\t<key>Request</key>\n\t<string>QueryType</string>\n</dict>\n</plist>\n")
        blen = @idevice.receive_data(4)
        blen.size.should == 4
        len = blen.unpack("N").first
        dat = @idevice.receive_data(len)
        dat.size.should == len
        dat.should =~ /^<\?xml/

      ensure
        @idevice.disconnect if @idevice.connected?
      end
    end

    it "should fail connect to the telnet port" do
      begin
        lambda{ @idevice.connect(23).should be_false }.should raise_error
        @idevice.should_not be_connected
        @idevice.should be_disconnected

      ensure
        @idevice.disconnect if @idevice.connected?
      end
    end
  end

end

