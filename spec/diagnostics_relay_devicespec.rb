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

describe Idevice::DiagnosticsRelayClient do
  before :all do
    @idevice = shared_idevice
  end

  before :each do
    @drc = Idevice::DiagnosticsRelayClient.attach(idevice:@idevice)
  end

  after :each do
    @drc.goodbye rescue nil
  end

  it "should attach" do
    @drc.should be_a Idevice::DiagnosticsRelayClient
  end

  it "should request diagnostics" do
    result = @drc.diagnostics("All")
    result.should be_a Hash
    result.should have_key "WiFi"
    result.should have_key "GasGauge"
    result["WiFi"].keys.sort.should == ["Active", "Status"]
    result["GasGauge"].keys.sort.should == ["CycleCount", "DesignCapacity", "FullChargeCapacity", "Status"]
  end

  it "should request All diagnostics by default" do
    result = @drc.diagnostics()
    result.should be_a Hash
    result.should have_key "WiFi"
    result.should have_key "GasGauge"
    result["WiFi"].keys.sort.should == ["Active", "Status"]
    result["GasGauge"].keys.sort.should == ["CycleCount", "DesignCapacity", "FullChargeCapacity", "Status"]
  end

  it "should request WiFi diagnostics" do
    result = @drc.diagnostics("WiFi")
    result.should be_a Hash
    result.keys.should == ["WiFi"]
    result["WiFi"].keys.sort.should == ["Active", "Status"]
  end

  it "should request GasGauge diagnostics" do
    result = @drc.diagnostics("GasGauge")
    result.should be_a Hash
    result.keys.should == ["GasGauge"]
    result["GasGauge"].keys.sort.should == ["CycleCount", "DesignCapacity", "FullChargeCapacity", "Status"]
  end

  it "should raise an error for invalid diagnostic types " do
    lambda{ @drc.diagnostics("SomeBogusType") }.should raise_error(Idevice::DiagnosticsRelayError)
  end

  it "should query mobilegestalt" do
    result = @drc.mobilegestalt("UniqueDeviceID")
    result.should be_a Hash
    result.keys.should == ["MobileGestalt"]
    result["MobileGestalt"].keys.sort.should == ["Status", "UniqueDeviceID"]
    result["MobileGestalt"]["Status"].should == "Success"
    result["MobileGestalt"]["UniqueDeviceID"].should =~ /^[a-f0-9]{40}$/i
  end

  it "should query ioregistry entries"

  it "should query the Root ioregistry plane" do
    result = @drc.ioregistry_plane("Root")
    result.should be_a Hash
    result.keys.should == ["IORegistry"]
    result["IORegistry"].should be_a Hash
    result["IORegistry"]["name"].should == "Root"
    result["IORegistry"]["children"].should be_empty
  end

  it "should query the IOPower ioregistry plane" do
    result = @drc.ioregistry_plane("IOPower")
    result.should be_a Hash
    result.keys.should == ["IORegistry"]
    result["IORegistry"].should be_a Hash
    result["IORegistry"]["name"].should == "Root"
    result["IORegistry"]["children"].should_not be_empty
  end

  it "should say goodbye to disconnect from the service" do
    @drc.goodbye.should be_true
    lambda{ @drc.diagnostics }.should raise_error(Idevice::DiagnosticsRelayError)
  end

  it "should put a device to sleep" do
    pending "don't actually put the device to sleep"
    @drc.sleep
  end

  it "should restart a device" do
    pending "don't actually reboot the device"
    @drc.restart(0) #(with optional flags arg)
  end

  it "should shutdown a device" do
    pending "don't actually shutdown the device"
    @drc.shutdown(0) #(with optional flags arg)
  end

end
