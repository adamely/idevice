require 'ffi'
require 'idev/c'
require 'stringio'

module Idev
  class IdeviceLibError < StandardError
  end

  def self._handle_idev_error(&block)
    ret = block.call()
    if ret != :SUCCESS
      raise IdeviceLibError, "Library error: #{ret}"
    end
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
        ::Idev._handle_idev_error { C.idevice_new(tmpptr, @udid) }
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
        ::Idev._handle_idev_error{ C.idevice_get_udid(self, udid_ptr) }
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
        ::Idev._handle_idev_error{ C.idevice_get_handle(self, tmpptr) }
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
        Idev._handle_idev_error{ C.idevice_connect(idevice, port, tmpptr) }
        idev_connection = tmpptr.read_pointer
        if idev_connection.null?
          raise IdeviceLibError, "idevice_connect returned a null idevice_connection_t"
        else
          return new(idev_connection)
        end
      end
    end

    def disconnect
      ::Idev._handle_idev_error{ C.idevice_disconnect(self) }
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
            ::Idev._handle_idev_error { C.idevice_connection_send(self, data_ptr, data_ptr.size, sent_bytes) }
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

          if ierr != :UNKNOWN_ERROR # seems to indicate end of data/connection
            Idev._handle_idev_error{ ierr }
          end
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
          Idev._handle_idev_error { C.idevice_connection_receive_timeout(self, data_ptr, data_ptr.size, recv_bytes, timeout) }
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
