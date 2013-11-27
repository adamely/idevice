require 'ffi'
require "idev/c"

module Idev
  class IdeviceLibError < StandardError
  end

  class Idevice
    def initialize(udid=nil)
      @udid = udid

      FFI::MemoryPointer.new(:pointer) do |tmpptr|
        _handle_idev_error { C.idevice_new(tmpptr, udid) }
        @_idev_ptr = tmpptr.read_pointer
      end
    end

    def ready?
      not destroyed?
    end

    def destroy
      _handle_idev_error{ C.idevice_free(_idev_ptr) }
    ensure
      @_idev_ptr = nil
    end

    def destroyed?
      @_idev_ptr.nil?
    end

    def udid
      return @udid if @udid

      @udid = nil
      FFI::MemoryPointer.new(:pointer) do |udid_ptr|
        _handle_idev_error{ C.idevice_get_udid(_idev_ptr, udid_ptr) }
        unless udid_ptr.read_pointer.null?
          @udid = udid_ptr.read_pointer.read_string
          LibC.free(udid_ptr.read_pointer)
        end
      end
      return @udid
    end

    def handle
      return @handle if @handle

      @handle = nil
      FFI::MemoryPointer.new(:uint32) do |tmpptr|
        _handle_idev_error{ C.idevice_get_handle(_idev_ptr, tmpptr) }
        @handle = tmpptr.read_uint32
      end
    end

    def connect port
      return true if connected?

      @_idev_connection_ptr = nil
      FFI::MemoryPointer.new(:pointer) do |tmpptr|
        _handle_idev_error{ C.idevice_connect(_idev_ptr, port, tmpptr) }
        @_idev_connection_ptr = tmpptr.read_pointer
      end
      return connected?
    end

    def connected?
      not disconnected?
    end

    def disconnect
      _handle_idev_error{ C.idevice_disconnect(_idev_connection_ptr) }
    ensure
      @_idev_connection_ptr = nil
    end

    def disconnected?
      @_idev_connection_ptr.nil?
    end

    private
    def _idev_ptr
      return @_idev_ptr if @_idev_ptr
      raise "device not initialize"
    end

    def _idev_connection_ptr
      return @_idev_connection_ptr if @_idev_connection_ptr
      raise "device not connected"
    end

    def _handle_idev_error
      ret = yield()
      if ret != :SUCCESS
        raise IdeviceLibError, "Library error: #{ret}"
      end
    end
  end
end
