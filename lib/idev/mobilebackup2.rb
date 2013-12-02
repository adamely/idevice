require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class MobileBackup2Error < IdeviceLibError
  end

  def self._handle_mb2_error(&block)
    err = block.call
    if err != :SUCCESS
      raise MobileBackup2Error, "Mobile backup error: #{err}"
    end
  end

  class MobileBackup2Client < C::ManagedOpaquePointer
    def self.release(ptr)
      C.mobilebackup2_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      idevice = opts[:idevice] || Idevice.attach(opts)
      ldsvc = opts[:lockdown_service]
      unless ldsvc
        ldclient = opts[:lockdown_client] || LockdownClient.attach(opts.merge(idevice:idevice))
        ldsvc = ldclient.start_service("com.apple.mobilebackup2")
      end

      FFI::MemoryPointer.new(:pointer) do |p_mb|
        Idev._handle_mb2_error{ C.mobilebackup2_client_new(idevice, ldsvc, p_mb) }
        mb = p_mb.read_pointer
        raise MisAgentError, "mobilebackup2_client_new returned a NULL client" if mb.null?
        return new(mb)
      end
    end

  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS          ,     0,
      :INVALID_ARG      ,    -1,
      :PLIST_ERROR      ,    -2,
      :MUX_ERROR        ,    -3,
      :BAD_VERSION      ,    -4,
      :REPLY_NOT_OK     ,    -5,
      :NO_COMMON_VERSION,    -6,
      :UNKNOWN_ERROR    ,  -256,
    ), :mobilebackup2_error_t

    #mobilebackup2_error_t mobilebackup2_client_new(idevice_t device, lockdownd_service_descriptor_t service, mobilebackup2_client_t * client);
    attach_function :mobilebackup2_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :mobilebackup2_error_t

    #mobilebackup2_error_t mobilebackup2_client_free(mobilebackup2_client_t client);
    attach_function :mobilebackup2_client_free, [MobileBackup2Client], :mobilebackup2_error_t

    #mobilebackup2_error_t mobilebackup2_send_message(mobilebackup2_client_t client, const char *message, plist_t options);
    attach_function :mobilebackup2_send_message, [MobileBackup2Client, :string, Plist_t], :mobilebackup2_error_t

    #mobilebackup2_error_t mobilebackup2_receive_message(mobilebackup2_client_t client, plist_t *msg_plist, char **dlmessage);
    attach_function :mobilebackup2_receive_message, [MobileBackup2Client, :pointer, :pointer], :mobilebackup2_error_t

    #mobilebackup2_error_t mobilebackup2_send_raw(mobilebackup2_client_t client, const char *data, uint32_t length, uint32_t *bytes);
    attach_function :mobilebackup2_send_raw, [MobileBackup2Client, :pointer, :uint32, :pointer], :mobilebackup2_error_t

    #mobilebackup2_error_t mobilebackup2_receive_raw(mobilebackup2_client_t client, char *data, uint32_t length, uint32_t *bytes);
    attach_function :mobilebackup2_receive_raw, [MobileBackup2Client, :pointer, :uint32, :pointer], :mobilebackup2_error_t

    #mobilebackup2_error_t mobilebackup2_version_exchange(mobilebackup2_client_t client, double local_versions[], char count, double *remote_version);
    attach_function :mobilebackup2_version_exchange, [MobileBackup2Client, :pointer, :char, :pointer], :mobilebackup2_error_t

    #mobilebackup2_error_t mobilebackup2_send_request(mobilebackup2_client_t client, const char *request, const char *target_identifier, const char *source_identifier, plist_t options);
    attach_function :mobilebackup2_send_request, [MobileBackup2Client, :string, :string, :string, Plist_t], :mobilebackup2_error_t

    #mobilebackup2_error_t mobilebackup2_send_status_response(mobilebackup2_client_t client, int status_code, const char *status1, plist_t status2);
    attach_function :mobilebackup2_send_status_response, [MobileBackup2Client, :int, :string, Plist_t], :mobilebackup2_error_t

  end
end
