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

describe Plist do
  it "should parse a xml plist to a hash" do
    hash = Plist.parse_xml(sample_file("plist.xml").read)
    hash.should be_a Hash
    hash.should == {"Label" => "idevspecs", "Request" => "QueryType"}
  end

  it "should parse a binary plist to a hash" do
    hash = Plist.parse_binary(sample_file("plist.bin").read)
    hash.should be_a Hash
    hash.should == {"Label" => "idevspecs", "Request" => "QueryType"}
  end

  it "should parse a xml plist file to a data object" do
    data = Plist.parse_xml(sample_file("plist_data.xml").read)
    data.should be_a StringIO
    data.string.should == "\u263a hey look it is a raw data blob \u263a"
  end

  it "should parse a binary plist file to a data object" do
    data = Plist.parse_binary(sample_file("plist_data.bin").read)
    data.should be_a StringIO
    data.string.should == "\u263a hey look it is a raw data blob \u263a"
  end

  it "should parse a ASCII encoded binary plist string to a data object" do
    rawdata = "bplist00O\x10&\xE2\x98\xBA hey look it is a raw data blob \xE2\x98\xBA\b\x00\x00\x00\x00\x00\x00\x01\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x001"
    data = Plist.parse_binary(rawdata)
    data.should be_a StringIO
    data.string.should == "\u263a hey look it is a raw data blob \u263a"
  end

  it "should parse a utf-8 encoded binary plist string to a data object" do
    rawdata = "bplist00O\u0010&\u263a hey look it is a raw data blob \u263a\b\u0000\u0000\u0000\u0000\u0000\u0000\u0001\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u00001"
    data = Plist.parse_binary(rawdata)
    data.should be_a StringIO
    data.string.should == "\u263a hey look it is a raw data blob \u263a"
  end

  it "should parse a xml plist to plist pointer" do
    ptr = Plist.xml_to_pointer(sample_file("plist.xml").read)
    ptr.should be_a FFI::Pointer
  end

  it "should parse a binary plist to plist pointer" do
    ptr = Plist.binary_to_pointer(sample_file("plist.bin").read)
    ptr.should be_a FFI::Pointer
  end

  it "should convert a plist pointer from and to a hash" do
    ptr = Idevice::Plist_t.new_dict
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    hash = ptr.to_ruby
    hash.should == {}
  end

  it "should create a plist pointer from and to an array" do
    ptr = Idevice::Plist_t.new_array
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    ary = ptr.to_ruby
    ary.should == []
  end

  it "should convert a plist pointer from and to a string" do
    ptr = Idevice::Plist_t.new_string("foobadoo")
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    str = ptr.to_ruby
    str.should == "foobadoo"
  end

  it "should convert a plist pointer from and to a string using from_ruby" do
    ptr = Idevice::Plist_t.from_ruby("foobadoo")
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    str = ptr.to_ruby
    str.should == "foobadoo"
  end

  it "should convert a plist pointer from and to bool" do
    ptr = Idevice::Plist_t.new_bool(false)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    bool = ptr.to_ruby
    bool.should == false

    ptr = Idevice::Plist_t.new_bool(true)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    bool = ptr.to_ruby
    bool.should == true
  end

  it "should convert a plist pointer from and to bool using from_ruby" do
    ptr = Idevice::Plist_t.from_ruby(false)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    bool = ptr.to_ruby
    bool.should == false

    ptr = Idevice::Plist_t.from_ruby(true)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    bool = ptr.to_ruby
    bool.should == true
  end


  it "should convert a plist pointer from and to an unsigned int" do
    ptr = Idevice::Plist_t.new_uint(0xdeadbeef)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    val = ptr.to_ruby
    val.should == 0xdeadbeef
  end

  it "should convert a negative number to an unsigned 64-bit int" do
    ptr = Idevice::Plist_t.from_ruby(-2)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    val = ptr.to_ruby
    val.should == 0xfffffffffffffffe
  end

  it "should convert a plist pointer from and to an unsigned int using from_ruby" do
    ptr = Idevice::Plist_t.from_ruby(0xdeadbeef)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    val = ptr.to_ruby
    val.should == 0xdeadbeef
  end

  it "should convert a plist pointer from and to a real number" do
    ptr = Idevice::Plist_t.new_real(1234.567)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    val = ptr.to_ruby
    val.should == 1234.567
  end

  it "should convert a plist pointer from and to a real number from an integer" do
    ptr = Idevice::Plist_t.new_real(1234)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    val = ptr.to_ruby
    val.should == 1234.0
  end


  it "should convert a plist pointer from and to a real number using from_ruby" do
    ptr = Idevice::Plist_t.from_ruby(1234.567)
    ptr.should be_a FFI::Pointer
    ptr.should_not be_null
    val = ptr.to_ruby
    val.should == 1234.567
  end

  it "should convert a plist pointer from and to raw data" do
    ptr = Idevice::Plist_t.new_data("some data here")
    ptr.should be_a FFI::Pointer
    val = ptr.to_ruby
    val.should be_a StringIO
    val.string.should == "some data here"
  end

  it "should convert a plist pointer from and to raw data using from_ruby" do
    ptr = Idevice::Plist_t.from_ruby(StringIO.new("some data here"))
    ptr.should be_a FFI::Pointer
    val = ptr.to_ruby
    val.should be_a StringIO
    val.string.should == "some data here"
  end

  it "should convert a plist date pointer from and to a ruby"

  it "should convert a plist date pointer from and to a ruby using from_ruby"

end
