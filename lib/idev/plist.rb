require 'idev/c'
require 'plist'

module Plist
  C = Idev::C

  def self.xml_to_pointer(xml)
    ::Idev::C::Plist_t.from_xml(xml)
  end

  def self.binary_to_pointer(data)
    ::Idev::C::Plist_t.from_binary(data)
  end

  def self.parse_binary(data)
    plist_ptr = binary_to_pointer(data)
    if plist_ptr
      res = pointer_to_ruby(plist_ptr)
      return res
    end
  end

  def self.pointer_to_ruby(plist_ptr)
    plist_ptr.to_ruby
  end
end

module PlistToPointer
  def to_plist_pointer
    ::Plist.xml_to_pointer(self.to_plist)
  end
end

Hash.extend(PlistToPointer)
Array.extend(PlistToPointer)

