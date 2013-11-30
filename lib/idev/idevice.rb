require 'ffi'
require 'idev/c'
require 'stringio'

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
          C.free(udid_ptr.read_pointer)
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
      raise IdeviceLibError, "device is already connected" if connected?

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
      _handle_idev_error{ C.idevice_disconnect(@_idev_connection_ptr) } if @_idev_connection_ptr
    ensure
      @_idev_connection_ptr = nil
    end

    def send_data(data)
      FFI::MemoryPointer.from_bytes(data) do |data_ptr|
        FFI::MemoryPointer.new(:uint32) do |sent_bytes|
          begin
            _handle_idev_error { C.idevice_connection_send(_idev_connection_ptr, data_ptr, data_ptr.size, sent_bytes) }
            sent = sent_bytes.read_uint32
            break if sent == 0
            data_ptr += sent
          end while data_ptr.size > 0
        end
      end
      return
    end

    # blocking read - optionally takes a block with each chunk read
    def receive_all(timeout=0)
      recvdata = StringIO.new unless block_given?

      FFI::MemoryPointer.new(8192) do |data_ptr|
        FFI::MemoryPointer.new(:uint32) do |recv_bytes|
          while (ierr=C.idevice_connection_receive_timeout(_idev_connection_ptr, data_ptr, data_ptr.size, recv_bytes, timeout)) == :SUCCESS
            chunk = data_ptr.read_bytes(recv_bytes.read_uint32) 
            if block_given?
              yield chunk
            else
              recvdata << chunk
            end

          end
          if ierr == :UNKNOWN_ERROR # seems to indicate end of data/connection
            self.disconnect if timeout == 0
          else
            raise IdeviceLibError, "Library error: #{ierr}"
          end
        end
      end

      return recvdata.string unless block_given?
    end

    # read up to maxlen bytes
    def receive_data(maxlen, timeout=0)
      recvdata = StringIO.new

      FFI::MemoryPointer.new(maxlen) do |data_ptr|
        FFI::MemoryPointer.new(:uint32) do |recv_bytes|
          # one-shot, read up to max-len and we're done
          _handle_idev_error { C.idevice_connection_receive_timeout(_idev_connection_ptr, data_ptr, data_ptr.size, recv_bytes, timeout) }
          recvdata << data_ptr.read_bytes(recv_bytes.read_uint32)
        end
      end
      return recvdata.string
    end

    def disconnected?
      @_idev_connection_ptr.nil?
    end

    def pointer
      _idev_ptr
    end

    private
    def _idev_ptr
      return @_idev_ptr if @_idev_ptr
      raise "device not initialized"
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

  module C
    ffi_lib 'imobiledevice'

    typedef :pointer, :idevice_t
    typedef :pointer, :idevice_connection_t

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
    attach_function :idevice_connect, [:idevice_t, :uint16, :pointer], :idevice_error_t
    attach_function :idevice_disconnect, [:idevice_connection_t], :idevice_error_t

    # communication
    attach_function :idevice_connection_send, [:idevice_connection_t, :pointer, :uint32, :pointer], :idevice_error_t
    attach_function :idevice_connection_receive_timeout, [:idevice_connection_t, :pointer, :uint32, :pointer, :uint], :idevice_error_t
    attach_function :idevice_connection_receive, [:idevice_connection_t, :pointer, :uint32, :pointer], :idevice_error_t

    # misc
    attach_function :idevice_get_handle, [:idevice_t, :pointer], :idevice_error_t
    attach_function :idevice_get_udid, [:idevice_t, :pointer], :idevice_error_t
  end
end
