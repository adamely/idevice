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

describe Idevice::MobileSyncClient do
  before :each do
    @sync = Idevice::MobileSyncClient.attach(idevice:shared_idevice)
  end

  after :each do
  end

  it "should attach" do
    @sync.should be_a Idevice::MobileSyncClient
  end

  it "should send a plist"

  it "should receive a plist"

  it "should start synchronizing a data class with the device"

  it "should cancel"

  it "should finish"

  it "should get all records from a device"

  it "should get changes from a device"

  it "should clear all records on a device"

  it "should receive changes from a device"

  it "should acknowledge changes from a device"

  it "should signal it is ready to send changes from the computer"

  it "should send changes"

  it "should remap identifiers"


end
