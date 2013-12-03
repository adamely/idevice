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

describe Idevice::MobileBackup2Client do
  before :each do
    @mb2 = Idevice::MobileBackup2Client.attach(idevice:shared_idevice)
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


