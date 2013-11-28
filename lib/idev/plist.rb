require 'idev/c'
require 'plist'

module Plist
  C = Idev::C

  def self.xml_to_pointer(xml)
    FFI::MemoryPointer.from_bytes(xml) do |plist_xml|
      FFI::MemoryPointer.new(:pointer) do |out|
        C.plist_from_xml(plist_xml, plist_xml.size, out)
        if (out.null?)
          return nil
        else
          return out.read_pointer
        end
      end
    end
  end

  def self.binary_to_pointer(data)
    FFI::MemoryPointer.from_bytes(data) do |plist_bin|
      FFI::MemoryPointer.new(:pointer) do |out|
        C.plist_from_bin(plist_bin, plist_bin.size, out)
        if (out.null?)
          return nil
        else
          return out.read_pointer
        end
      end
    end
  end

  def self.parse_binary(data)
    plist_ptr = binary_to_pointer(data)
    if plist_ptr
      res = pointer_to_ruby(plist_ptr)
      free_pointer(plist_ptr)
      return res
    end
  end

  def self.pointer_to_ruby(plist_ptr)
    FFI::MemoryPointer.new(:pointer) do |plist_xml_p|
      FFI::MemoryPointer.new(:pointer) do |length_p|
        C.plist_to_xml(plist_ptr, plist_xml_p, length_p)
        length = length_p.read_uint32
        if plist_xml_p.null?
          return nil
        else
          ptr = plist_xml_p.read_pointer
          begin
            res = Plist.parse_xml(ptr.read_bytes(length))
          ensure
            C.free(ptr)
          end
          return res
        end
      end
    end
  end

  def self.free_pointer(ptr)
    Idev::C.plist_free(ptr) if ptr and not ptr.null?
  end
end

module PlistToPointer
  def to_plist_pointer
    ::Plist.xml_to_pointer(self.to_plist)
  end
end

Hash.extend(PlistToPointer)
Array.extend(PlistToPointer)

