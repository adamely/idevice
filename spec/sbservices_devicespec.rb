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

describe Idevice::SBSClient do
  before :each do
    @sbs = Idevice::SBSClient.attach(idevice:shared_idevice, lockdown_client:shared_lockdown_client)
  end

  it "should attach" do
    @sbs.should be_a Idevice::SBSClient
  end


  it "should get the icon state of the connected device" do
    state = @sbs.get_icon_state
    state.should be_a Array
  end

  it "should set the icon state" do
    pending "dont actually mess with icon state"
    @sbs.set_icon_state({"somthing" => 'here'})
  end

  it "should get icon pngdata" do
    data = @sbs.get_icon_pngdata("com.apple.Preferences")
    data.should be_a String
    shell_pipe(data[0..256], "file -").should =~ /PNG image data/
  end

  it "should get device orientation" do
    orientation = @sbs.get_interface_orientation
    [ :PORTRAIT,             # => 1,
      :PORTRAIT_UPSIDE_DOWN, # => 2,
      :LANDSCAPE_RIGHT,      # => 3,
      :LANDSCAPE_LEFT,       # => 4,
    ].should include(orientation)
  end

  it "should get the homes screen wallpaper pngdata" do
    data = @sbs.get_home_screen_wallpaper_pngdata
    data.should be_a String
    shell_pipe(data[0..256], "file -").should =~ /PNG image data/
  end
end

