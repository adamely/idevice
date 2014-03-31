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

describe Idevice::MisAgentClient do
  before :each do
    @mis = Idevice::MisAgentClient.attach(idevice:shared_idevice, lockdown_client:shared_lockdown_client)
  end

  it "should attach" do
    @mis.should be_a Idevice::MisAgentClient
  end

  it "should list installed profiles" do
    profiles = @mis.profiles
    profiles.should be_a Array
    profiles.each do |profile|
      profile.should be_a StringIO
    end
  end

  it "should install a profile"

  it "should remove an installed profile"
end
