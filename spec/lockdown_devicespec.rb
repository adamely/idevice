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

describe Idevice::LockdownClient do
  it "should attach without arguments" do
    client = Idevice::LockdownClient.attach
    client.should be_a Idevice::LockdownClient
    client.device_udid.should == client.get_value(nil, "UniqueDeviceID")
  end

  it "should attach with an instantiated idevice" do
    client = Idevice::LockdownClient.attach(idevice: Idevice::Idevice.attach)
    client.should be_a Idevice::LockdownClient
    client.device_udid.should == client.get_value(nil, "UniqueDeviceID")
  end

  context "an attached client" do
    before :each do
      @lockdown = Idevice::LockdownClient.attach(idevice:shared_idevice, lockdown_client:shared_lockdown_client)
    end

    after :each do
      @lockdown.goodbye if @lockdown
    end

    it "should attach" do
      @lockdown.should be_a Idevice::LockdownClient
    end

    it "should list sync data classes" do
      result = @lockdown.sync_data_classes
      result.should be_a Array
      result.count.should > 1
    end

    it "should query type" do
      @lockdown.query_type.should == "com.apple.mobile.lockdown"
    end

    it "should have a device_udid" do
      result = @lockdown.device_udid
      result.should be_a String
      result.should =~ /^[a-f0-9]{40}$/i
      result.should == @lockdown.get_value(nil, "UniqueDeviceID")
    end

    it "should have a device_name" do
      result = @lockdown.device_name
      result.should be_a String
      result.should == @lockdown.get_value(nil, "DeviceName")
    end

    it "should get a value for nil:UniqueDeviceID" do
      result = @lockdown.get_value(nil, "UniqueDeviceID")
      result.should be_a String
      result.should =~ /^[a-f0-9]{40}$/i
      result.should == @lockdown.device_udid
    end

    it "should not get a value for nil:BogusKey" do
      result = @lockdown.get_value(nil, "BogusKey")
      result.should be_nil
    end

    it "should get an empty hash for BogusDomain" do
      result = @lockdown.get_value("BogusDomain", nil)
      result.should == {}
    end

    it "should not get a value for BogusDomain:UniqueDeviceID" do
      result = @lockdown.get_value("BogusDomain", "UniqueDeviceID")
      result.should be_nil
    end

    it "should start an 'afc' lockdown service" do
      ldsvc = @lockdown.start_service("com.apple.afc")
      ldsvc.should_not be_nil
      ldsvc[:port].should > 1024
      [0,1].include?(ldsvc[:ssl_enabled]).should be_true
    end

    it "should raise an error starting a nonexistent lockdown service" do
      lambda{ @lockdown.start_service("nonexistent.service.garbage") }.should raise_error Idevice::IdeviceLibError
    end

  end
end
