
require "rubygems"
require 'plist'
require "ffi"

module FFI
  class MemoryPointer < Pointer
    def self.from_bytes(data)
      if block_given?
        new(data.size) do |p|
          p.write_bytes(data)
          yield(p)
        end
      else
        p = new(data.size)
        p.write_bytes(data)
        p
      end
    end

    def self.null_terminated_array_of_strings(strs)
      psize = FFI::MemoryPointer.size * (strs.count+1)
      pstrs = strs.map{|str| FFI::MemoryPointer.from_string(str) }
      if block_given?
        new(psize) do |aryp|
          aryp.write_array_of_pointer(pstrs)
          yield(aryp)
        end
      else
        aryp.instance_variable_set(:@_string_pointers, pstrs) # retain reference for garbage collection
        aryp.write_array_of_pointer(pstrs)
        return aryp
      end
    end
  end
end

module Idev
  module C
    extend FFI::Library

    class ManagedOpaquePointer < FFI::AutoPointer
      def initialize(pointer)
        raise NoMethodError, "release() not implemented for class #{self}" unless self.class.respond_to? :release
        raise ArgumentError, "Must supply a pointer to memory" unless pointer
        super(pointer, self.class.method(:release))
      end
    end

    #----------------------------------------------------------------------
    ffi_lib FFI::Library::LIBC

    # memory allocators
    attach_function :malloc, [:size_t], :pointer
    attach_function :calloc, [:size_t], :pointer
    attach_function :valloc, [:size_t], :pointer
    attach_function :realloc, [:pointer, :size_t], :pointer
    attach_function :free, [:pointer], :void

    # memory movers
    attach_function :memcpy, [:pointer, :pointer, :size_t], :pointer
    attach_function :bcopy, [:pointer, :pointer, :size_t], :void

  end
end

