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

require "rubygems"
require 'plist'
require "ffi"
require "thread"

module FFI
  class MemoryPointer < Pointer
    def self.from_bytes(data)
      if block_given?
        new(data.bytesize) do |p|
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

    Freelock = Mutex.new

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

