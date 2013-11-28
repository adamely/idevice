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

  it "should parse a xml plist to plist pointer" do
    begin
      ptr = Plist.xml_to_pointer(sample_file("plist.xml").read)
      ptr.should be_a FFI::Pointer
    ensure
      Plist.free_pointer(ptr) if ptr
    end
  end

  it "should parse a binary plist to plist pointer" do
    begin
      ptr = Plist.binary_to_pointer(sample_file("plist.bin").read)
      ptr.should be_a FFI::Pointer
    ensure
      Plist.free_pointer(ptr) if ptr
    end
  end

  it "should convert a plist pointer from and to a hash" do
    begin
      ptr = Idev::C.plist_new_dict
      ptr.should be_a FFI::Pointer
      ptr.should_not be_null
      hash = Plist.pointer_to_ruby(ptr)
      hash.should == {}
    ensure
      Plist.free_pointer(ptr) if ptr
    end
  end

  it "should create a plist pointer from and to an array" do
    begin
      ptr = Idev::C.plist_new_array
      ptr.should be_a FFI::Pointer
      ptr.should_not be_null
      ary = Plist.pointer_to_ruby(ptr)
      ary.should == []
    ensure
      Plist.free_pointer(ptr) if ptr
    end
  end

  it "should convert a plist pointer from and to a string" do
    begin
      ptr = Idev::C.plist_new_string("foobadoo")
      ptr.should be_a FFI::Pointer
      ptr.should_not be_null
      str = Plist.pointer_to_ruby(ptr)
      str.should == "foobadoo"
    ensure
      Plist.free_pointer(ptr) if ptr
    end
  end

  it "should convert a plist pointer from and to bool" do
    begin
      ptr = Idev::C.plist_new_bool(false)
      ptr.should be_a FFI::Pointer
      ptr.should_not be_null
      bool = Plist.pointer_to_ruby(ptr)
      bool.should == false
    ensure
      Plist.free_pointer(ptr) if ptr
    end
    begin
      ptr = Idev::C.plist_new_bool(true)
      ptr.should be_a FFI::Pointer
      ptr.should_not be_null
      bool = Plist.pointer_to_ruby(ptr)
      bool.should == true
    ensure
      Plist.free_pointer(ptr) if ptr
    end
  end

  it "should convert a plist pointer from and to an unsigned int" do
    begin
      ptr = Idev::C.plist_new_uint(0xdeadbeef)
      ptr.should be_a FFI::Pointer
      ptr.should_not be_null
      val = Plist.pointer_to_ruby(ptr)
      val.should == 0xdeadbeef
    ensure
      Plist.free_pointer(ptr) if ptr
    end
  end

  it "should convert a plist pointer from and to a real number" do
    begin
      ptr = Idev::C.plist_new_real(1234.567)
      ptr.should be_a FFI::Pointer
      ptr.should_not be_null
      val = Plist.pointer_to_ruby(ptr)
      val.should == 1234.567
    ensure
      Plist.free_pointer(ptr) if ptr
    end
  end
end

