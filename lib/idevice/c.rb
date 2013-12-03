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

module Idevice
  module LibHelpers
    def self.included(base)
      class << base
      private
        def _attach_helper(svcname, opts={})
          idevice = opts[:idevice] || Idevice.attach(opts)
          ldsvc = opts[:lockdown_service]
          unless ldsvc
            ldclient = opts[:lockdown_client] || LockdownClient.attach(opts.merge(idevice:idevice))
            ldsvc = ldclient.start_service(svcname)
          end

          FFI::MemoryPointer.new(:pointer) do |p_client|
            yield idevice, ldsvc, p_client
          end
        end
      end
    end

  private

    def _unbound_list_to_array(p_unbound_list)
      ret = nil
      base = list = p_unbound_list.read_pointer
      unless list.null?
        ret = []
        until list.read_pointer.null?
          ret << list.read_pointer.read_string
          list += FFI::TypeDefs[:pointer].size
        end
        C.idevice_device_list_free(base)
      end
      return ret
    end

    def _infolist_to_hash(p_infolist)
      infolist = _unbound_list_to_array(p_infolist)
      if infolist
        return Hash[ infolist.each_slice(2).to_a.map{|k,v| [k.to_sym, v]} ]
      end
    end

  end

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

