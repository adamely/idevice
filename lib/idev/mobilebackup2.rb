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

    def send_message(message, opts=nil)
      if message.nil? and opts.nil?
        raise ArgumentError, "Both message and options hash may not be nil"
      end
      opts = opts.to_plist_t unless opts.nil?
      Idev._handle_mb2_error{ C.mobilebackup2_send_message(self, message, opts) }
      return true
    end

    def receive_message
      FFI::MemoryPointer.new(:pointer) do |p_msg|
        FFI::MemoryPointer.new(:pointer) do |p_dlmessage|
          Idev._handle_mb2_error{ C.mobilebackup2_receive_message(self, p_msg, p_dlmessage) }
          dlmessage = p_dlmessage.read_pointer
          msg = p_msg.read_pointer
          begin
            raise MobileBackup2Error, "mobilebackup2_receive_message returned a null message plist" if msg.null?
            ret = Plist_t.new(msg).to_ruby
            unless dlmessage.null?
              ret[:dlmessage] = dlmessage.read_string
            end
            return ret
          ensure
            C.free(dlmessage) unless dlmessage.nil? or dlmessage.null?
          end
        end
      end
    end

    def send_raw(data)
      FFI::MemoryPointer.from_bytes(data) do |p_data|
        FFI::MemoryPointer.new(:uint32) do |p_sentbytes|
          Idev._handle_mb2_error{ C.mobilebackup2_send_raw(self, p_data, p_data.size, p_sentbytes) }
          return p_sentbytes.read_uint32
        end
      end
    end

    def receive_raw(len)
      FFI::MemoryPointer.new(len) do |p_data|
        FFI::MemoryPointer.new(:uint32) do |p_rcvdbytes|
          Idev._handle_mb2_error{ C.mobilebackup2_receive_raw(self, p_data, p_data.size, p_rcvdbytes) }
          return p_data.read_bytes(p_rcvdbytes.read_uint32)
        end
      end
    end

    def version_exchange(local_versions)
      local_versions = local_versions.map{|x| x.to_f } # should throw an error if one is not a float/float-able
      FFI::MemoryPointer.new(FFI::TypeDefs[:double].size * local_versions.count) do |p_local_versions|
        p_local_versions.write_array_of_double(local_versions)
        FFI::MemoryPointer.new(:pointer) do |p_remote_version|
          Idev._handle_mb2_error{ C.mobilebackup2_version_exchange(self, p_local_versions, local_versions.count, p_remote_version) }
          return p_remote_version.read_double
        end
      end
    end

    def send_request(request, target_identifier, source_identifier, opts={})
      Idev._handle_mb2_error{ C.mobilebackup2_send_request(self, request, target_id, source_id, opts.to_plist_t) }
      return true
    end

    def send_status_response(status_code, status_message=nil, opts=nil)
      opts = opts.to_plist_t if opts
      Idev._handle_mb2_error{ C.mobilebackup2_send_status_response(self, status_code, status_message, opts) }
      return true
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
