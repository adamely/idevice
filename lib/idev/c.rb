
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

