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

require 'ffi'
require 'idevice/c'
require 'stringio'

module Idevice
  class IdeviceLibError < StandardError
  end

  class Idevice < C::ManagedOpaquePointer
    def self.release(ptr)
      C.idevice_free(ptr) unless ptr.null?
    end

    # Use this instead of 'new' to attach to an idevice using libimobiledevice
    # and instantiate a new idevice_t handle
    def self.attach(opts={})
      @udid = opts[:udid]

      FFI::MemoryPointer.new(:pointer) do |tmpptr|
        err = C.idevice_new(tmpptr, @udid)
        raise IdeviceLibError, "Idevice error: #{err}" if err != :SUCCESS

        idevice_t = tmpptr.read_pointer
        if idevice_t.null?
          raise IdeviceLibError, "idevice_new created a null pointer"
        else
          return new(tmpptr.read_pointer)
        end
      end
    end

    def udid
      return @udid if @udid

      @udid = nil
      FFI::MemoryPointer.new(:pointer) do |udid_ptr|
        err = C.idevice_get_udid(self, udid_ptr)
        raise IdeviceLibError, "Idevice error: #{err}" if err != :SUCCESS
        unless udid_ptr.read_pointer.null?
          @udid = udid_ptr.read_pointer.read_string
          C.free(udid_ptr.read_pointer)
        end
      end
      return @udid
    end

    def handle
      @handle = nil
      FFI::MemoryPointer.new(:uint32) do |tmpptr|
        err = C.idevice_get_handle(self, tmpptr)
        raise IdeviceLibError, "Idevice error: #{err}" if err != :SUCCESS
        return tmpptr.read_uint32
      end
    end

    def connect port
      IdeviceConnection.connect(self, port)
    end
  end

  class IdeviceConnection < C::ManagedOpaquePointer
    def self.release(ptr)
      C.idevice_disconnect(ptr) unless ptr.null? or ptr.disconnected?
    end

    def self.connect(idevice, port)
      FFI::MemoryPointer.new(:pointer) do |tmpptr|
        err = C.idevice_connect(idevice, port, tmpptr)
        raise IdeviceLibError, "Idevice error: #{err}" if err != :SUCCESS
        idev_connection = tmpptr.read_pointer
        if idev_connection.null?
          raise IdeviceLibError, "idevice_connect returned a null idevice_connection_t"
        else
          return new(idev_connection)
        end
      end
    end

    def disconnect
      err = C.idevice_disconnect(self)
      raise IdeviceLibError, "Idevice error: #{err}" if err != :SUCCESS
      @_disconnected = true
      nil
    end

    def connected?
      not disconnected?
    end

    def disconnected?
      @_disconnected == true
    end

    def send_data(data)
      FFI::MemoryPointer.from_bytes(data) do |data_ptr|
        FFI::MemoryPointer.new(:uint32) do |sent_bytes|
          begin
            err = C.idevice_connection_send(self, data_ptr, data_ptr.size, sent_bytes)
            raise IdeviceLibError, "Idevice error: #{err}" if err != :SUCCESS
            sent = sent_bytes.read_uint32
            break if sent == 0
            data_ptr += sent
          end while data_ptr.size > 0
        end
      end
      return
    end

    DEFAULT_RECV_TIMEOUT = 0
    DEFAULT_RECV_CHUNKSZ = 8192

    # blocking read - optionally yields to a block with each chunk read
    def receive_all(timeout=nil, chunksz=nil)
      timeout ||= DEFAULT_RECV_TIMEOUT
      chunksz ||= DEFAULT_RECV_CHUNKSZ
      recvdata = StringIO.new unless block_given?

      FFI::MemoryPointer.new(chunksz) do |data_ptr|
        FFI::MemoryPointer.new(:uint32) do |recv_bytes|
          while (ierr=C.idevice_connection_receive_timeout(self, data_ptr, data_ptr.size, recv_bytes, timeout)) == :SUCCESS
            chunk = data_ptr.read_bytes(recv_bytes.read_uint32) 
            if block_given?
              yield chunk
            else
              recvdata << chunk
            end
          end

          # UNKNOWN_ERROR seems to indicate end of data/connection
          raise IdeviceLibError, "Idevice error: #{ierr}" if ierr != :UNKNOWN_ERROR
        end
      end

      return recvdata.string unless block_given?
    end

    # read up to maxlen bytes
    def receive_data(maxlen, timeout=nil)
      timeout ||= DEFAULT_RECV_TIMEOUT
      recvdata = StringIO.new

      FFI::MemoryPointer.new(maxlen) do |data_ptr|
        FFI::MemoryPointer.new(:uint32) do |recv_bytes|
          # one-shot, read up to max-len and we're done
          err = C.idevice_connection_receive_timeout(self, data_ptr, data_ptr.size, recv_bytes, timeout)
          raise IdeviceLibError, "Idevice error: #{err}" if err != :SUCCESS
          recvdata << data_ptr.read_bytes(recv_bytes.read_uint32)
        end
      end
      return recvdata.string
    end
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS,               0,
      :INVALID_ARG,          -1,
      :UNKNOWN_ERROR,        -2,
      :NO_DEVICE,            -3,
      :NOT_ENOUGH_DATA,      -4,
      :BAD_HEADER,           -5,
      :SSL_ERROR,            -6,
    ), :idevice_error_t

    # discovery (synchronous)
    attach_function :idevice_set_debug_level, [:int], :void
    attach_function :idevice_get_device_list, [:pointer, :pointer], :idevice_error_t
    attach_function :idevice_device_list_free, [:pointer], :idevice_error_t

    # device structure creation and destruction
    attach_function :idevice_new, [:pointer, :string], :idevice_error_t
    attach_function :idevice_free, [:pointer], :idevice_error_t

    # connection/disconnection
    attach_function :idevice_connect, [Idevice, :uint16, :pointer], :idevice_error_t
    attach_function :idevice_disconnect, [IdeviceConnection], :idevice_error_t

    # communication
    attach_function :idevice_connection_send, [IdeviceConnection, :pointer, :uint32, :pointer], :idevice_error_t
    attach_function :idevice_connection_receive_timeout, [IdeviceConnection, :pointer, :uint32, :pointer, :uint], :idevice_error_t
    attach_function :idevice_connection_receive, [IdeviceConnection, :pointer, :uint32, :pointer], :idevice_error_t

    # misc
    attach_function :idevice_get_handle, [Idevice, :pointer], :idevice_error_t
    attach_function :idevice_get_udid, [Idevice, :pointer], :idevice_error_t
  end
end
