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

describe Idevice::ImageMounterClient do
  before :each do
    @imgmounter = Idevice::ImageMounterClient.attach(idevice:shared_idevice)
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

