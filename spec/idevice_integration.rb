require_relative 'spec_helper'

describe Idev::Idevice do

  context "with an attached device" do
    before :all do
      @idevice = Idev::Idevice.attach()
    end

    it "should attach" do
      @idevice.should be_a Idev::Idevice
    end

    it "should have a udid" do
      @idevice.udid.should_not be_nil
      @idevice.udid.should =~ /^[a-f0-9]{40}$/i
    end

    it "should have a handle" do
      @idevice.handle.should_not be_nil
      @idevice.handle.should be_a Numeric
    end

    it "should fail to connect to the telnet port" do
      lambda{ @idevice.connect(23).should be_false }.should raise_error
    end

    context "connecting to lockdown" do
      it "should connect to the lockdownd port" do
        begin
          connection = @idevice.connect(62078)
          connection.should be_a Idev::IdeviceConnection
          connection.should be_connected
          connection.should_not be_disconnected
        ensure
          connection.disconnect if connection
        end
      end

      it "should query lockdownd" do
        begin
          connection = @idevice.connect(62078)
          connection.should be_a Idev::IdeviceConnection
          connection.should be_connected
          connection.should_not be_disconnected

          connection.send_data("\000\000\001\032<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>Label</key>\n\t<string>idevspecs</string>\n\t<key>Request</key>\n\t<string>QueryType</string>\n</dict>\n</plist>\n")
          blen = connection.receive_data(4)
          blen.size.should == 4
          len = blen.unpack("N").first
          dat = connection.receive_data(len)
          dat.size.should == len
          dat.should =~ /^<\?xml /

        ensure
          connection.disconnect if connection
        end
      end
    end
  end

end

