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

