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

describe Idevice::ImageMounterClient do
  before :each do
    @imgmounter = Idevice::ImageMounterClient.attach(idevice:shared_idevice, lockdown_client:shared_lockdown_client)
  end

  after :each do
    @imgmounter.hangup rescue nil
  end

  it "should attach" do
    @imgmounter.should be_a Idevice::ImageMounterClient
  end

  it "should look up whether the Developer image is mounted" do
    res=@imgmounter.lookup_image("Developer")
    res["Status"].should == "Complete"
    res.should have_key "ImagePresent"
  end

  it "should look up whether the Developer image is mounted (by default)" do
    res=@imgmounter.lookup_image
    res["Status"].should == "Complete"
    res.should have_key "ImagePresent"
  end

  it "should look up whether the Debug image is mounted" do
    res=@imgmounter.lookup_image("Debug")
    res["Status"].should == "Complete"
    res.should have_key "ImagePresent"
  end

  it "should look up whether an arbitrary image is mounted" do
    @imgmounter.lookup_image("SomebogusImageName").should == {"ImagePresent"=>false, "Status"=>"Complete"}
  end

  it "should hangup" do
    @imgmounter.hangup.should be_true
    lambda{ @imgmounter.lookup_image }.should raise_error(Idevice::ImageMounterError)
  end

  it "should mount an image"
end

