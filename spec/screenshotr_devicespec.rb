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

describe Idevice::ScreenShotrClient do
  before :each do
    pending "needs developer disk mounted" unless ENV["DEVTESTS"]
    @ss = Idevice::ScreenShotrClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @ss.should be_a Idevice::ScreenShotrClient
  end

  it "should take a screenshot" do
    data = @ss.take_screenshot
    data.should be_a String
    shell_pipe(data[0..256], "file -").should =~ /image data/
  end
end

