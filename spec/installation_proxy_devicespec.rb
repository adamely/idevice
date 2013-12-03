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

describe Idevice::InstProxyClient do
  before :each do
    @instproxy = Idevice::InstProxyClient.attach(idevice:shared_idevice)
  end

  it "should attach" do
    @instproxy.should be_a Idevice::InstProxyClient
  end

  it "should browse installed apps" do
    browsedata = @instproxy.browse()
    browsedata.should be_a Array
    browsedata.map{|x| x.class }.uniq.should == [Hash]
    browsedata.map{|x| x["ApplicationType"]}.should include "System"
  end

  it "should install an application"

  it "should upgrade an application"

  it "should uninstall an application"

  it "should lookup archives"

  it "should archive an application"

  it "should restore an archived application"

  it "should remove an archive"

end

