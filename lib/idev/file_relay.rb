
module Idev
  class FileRelayError < IdeviceLibError
  end

  def self._handle_fr_error(&block)
    err = block.call
    if err != :SUCCESS
      raise FileRelayError, "File Relay Error: #{err}"
    end
  end

  class FileRelayClient < C::ManagedOpaquePointer
    include LibHelpers
    def self.release(ptr)
      C.file_relay_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      _attach_helper("com.apple.mobile.file_relay", opts) do |idevice,ldsvc,p_frc|
        Idev._handle_fr_error{ C.file_relay_client_new(idevice, ldsvc, p_frc) }
        frc = p_frc.read_pointer
        raise FileRelayError, "file_relay_client_new returned a NULL client" if frc.null?
        return new(frc)
      end
    end

    def request_sources(*sources, &block)
      FFI::MemoryPointer.null_terminated_array_of_strings(sources) do |p_sources|
        FFI::MemoryPointer.new(:pointer) do |p_conn|
          Idev._handle_fr_error{ C.file_relay_request_sources(self, p_sources, p_conn) }
          conn = p_conn.read_pointer
          raise FileRelayError, "file_relay_request_sources returned a NULL connection" if conn.null?
          iconn = IdeviceConnection.new(conn)
          ret = iconn.receive_all(nil, &block)
          return ret
        end
      end
    end
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS        ,       0,
      :INVALID_ARG    ,      -1,
      :PLIST_ERROR    ,      -2,
      :MUX_ERROR      ,      -3,
      :INVALID_SOURCE ,      -4,
      :STAGING_EMPTY  ,      -5,
      :UNKNOWN_ERROR  ,    -256,
    ), :file_relay_error_t

    #file_relay_error_t file_relay_client_new(idevice_t device, lockdownd_service_descriptor_t service, file_relay_client_t *client);
    attach_function :file_relay_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :file_relay_error_t

    #file_relay_error_t file_relay_client_free(file_relay_client_t client);
    attach_function :file_relay_client_free, [FileRelayClient], :file_relay_error_t

    #file_relay_error_t file_relay_request_sources(file_relay_client_t client, const char **sources, idevice_connection_t *connection);
    attach_function :file_relay_request_sources, [FileRelayClient, :pointer, :pointer], :file_relay_error_t

  end
end
