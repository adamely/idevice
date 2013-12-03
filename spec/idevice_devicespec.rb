#
# Copyright (c) 2013 Eric Monti
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require_relative 'spec_helper'

describe Idevice do
  it "should list attached devices" do
    devlist = Idevice.device_list
    devlist.count.should > 0
    devlist.each do |dev|
      dev.should =~ /^[a-f0-9]{40}$/i
    end
  end
end

describe Idevice::Idevice do

  context "with an attached device" do
    before :all do
      @idevice = Idevice::Idevice.attach()
    end

    it "should attach" do
      @idevice.should be_a Idevice::Idevice
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
          connection.should be_a Idevice::IdeviceConnection
          connection.should be_connected
          connection.should_not be_disconnected
        ensure
          connection.disconnect if connection
        end
      end

      it "should query lockdownd" do
        begin
          connection = @idevice.connect(62078)
          connection.should be_a Idevice::IdeviceConnection
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

