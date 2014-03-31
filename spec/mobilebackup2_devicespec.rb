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

describe Idevice::MobileBackup2Client do
  before :each do
    @mb2 = Idevice::MobileBackup2Client.attach(idevice:shared_idevice, lockdown_client:shared_lockdown_client)
  end

  after :each do
  end

  it "should attach" do
    @mb2.should be_a Idevice::MobileBackup2Client
  end

  it "should exchange versions" do
    versions = [1.0, 1.1, 1.2, 1.3, 2.0, 2.1, 2.2, 2.3]
    versions.should include(@mb2.version_exchange(versions))
  end

  it "should raise an exception attempting to negotiate an invalid version" do
    lambda{ @mb2.version_exchange([999.99]) }.should raise_error Idevice::MobileBackup2Error
  end

  it "should send a message"

  it "should receive a message"

  it "should send a raw message"

  it "should receive a raw message"

  it "should send a request"

  it "should send a status response"

end


