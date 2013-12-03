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

require 'spec_helper'

describe Idevice::FileRelayClient do
  before :each do
    @frc = Idevice::FileRelayClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @frc.should be_a Idevice::FileRelayClient
  end

  it "should return an error when requesting invalid sources" do
    lambda{ @frc.request_sources("this source is lies") }.should raise_error(Idevice::FileRelayError)
  end

  it "should request and receive CrashReporter logs" do
    crashdata = @frc.request_sources("CrashReporter")
    crashdata.should be_a String

    # the returned data is actually a gzip-compressed cpio
    shell_pipe(crashdata[0..256], "file -").should =~ /gzip compressed data, from Unix\n$/
    shell_pipe(crashdata, "cpio -t").should =~ /^\.\/var\/mobile\/Library/
  end
end

