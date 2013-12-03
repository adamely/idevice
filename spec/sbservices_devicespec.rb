#
# Copyright (c) 2013 Eric Monti
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require_relative 'spec_helper'

describe Idevice::SBSClient do
  before :each do
    @sbs = Idevice::SBSClient.attach(idevice:shared_idevice)
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

