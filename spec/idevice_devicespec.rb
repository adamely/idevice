#
# Copyright (c) 2013 Eric Monti - Bluebox Security
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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

