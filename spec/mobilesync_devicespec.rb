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
