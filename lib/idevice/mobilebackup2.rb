require 'idevice/c'
require 'idevice/plist'
require 'idevice/idevice'
require 'idevice/lockdown'

module Idevice
  class MobileBackup2Error < IdeviceLibError
  end

  # Used to backup and restore of all device data (mobilebackup2, iOS4+ only)
  class MobileBackup2Client < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.mobilebackup2_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      _attach_helper("com.apple.mobilebackup2", opts) do |idevice, ldsvc, p_mb2|
        err = C.mobilebackup2_client_new(idevice, ldsvc, p_mb2)
        raise MobileBackup2Error, "Mobile backup error: #{err}" if err != :SUCCESS

        mb2 = p_mb2.read_pointer
        raise MobileBackup2Error, "mobilebackup2_client_new returned a NULL client" if mb2.null?
        return new(mb2)
      end
    end

    def send_message(message, opts=nil)
      if message.nil? and opts.nil?
        raise ArgumentError, "Both message and options hash may not be nil"
      end
      opts = opts.to_plist_t unless opts.nil?
      err = C.mobilebackup2_send_message(self, message, opts)
      raise MobileBackup2Error, "Mobile backup error: #{err}" if err != :SUCCESS

      return true
    end

    def receive_message
      FFI::MemoryPointer.new(:pointer) do |p_msg|
        FFI::MemoryPointer.new(:pointer) do |p_dlmessage|
          err = C.mobilebackup2_receive_message(self, p_msg, p_dlmessage)
          raise MobileBackup2Error, "Mobile backup error: #{err}" if err != :SUCCESS

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
          err = C.mobilebackup2_send_raw(self, p_data, p_data.size, p_sentbytes)
          raise MobileBackup2Error, "Mobile backup error: #{err}" if err != :SUCCESS

          return p_sentbytes.read_uint32
        end
      end
    end

    def receive_raw(len)
      FFI::MemoryPointer.new(len) do |p_data|
        FFI::MemoryPointer.new(:uint32) do |p_rcvdbytes|
          err = C.mobilebackup2_receive_raw(self, p_data, p_data.size, p_rcvdbytes)
          raise MobileBackup2Error, "Mobile backup error: #{err}" if err != :SUCCESS

          return p_data.read_bytes(p_rcvdbytes.read_uint32)
        end
      end
    end

    def version_exchange(local_versions)
      local_versions = local_versions.map{|x| x.to_f } # should throw an error if one is not a float/float-able
      FFI::MemoryPointer.new(FFI::TypeDefs[:double].size * local_versions.count) do |p_local_versions|
        p_local_versions.write_array_of_double(local_versions)
        FFI::MemoryPointer.new(:pointer) do |p_remote_version|
          err = C.mobilebackup2_version_exchange(self, p_local_versions, local_versions.count, p_remote_version)
          raise MobileBackup2Error, "Mobile backup error: #{err}" if err != :SUCCESS

          return p_remote_version.read_double
        end
      end
    end

    def send_request(request, target_identifier, source_identifier, opts={})
      err = C.mobilebackup2_send_request(self, request, target_id, source_id, opts.to_plist_t)
      raise MobileBackup2Error, "Mobile backup error: #{err}" if err != :SUCCESS

      return true
    end

    def send_status_response(status_code, status_message=nil, opts=nil)
      opts = opts.to_plist_t if opts
      err = C.mobilebackup2_send_status_response(self, status_code, status_message, opts)
      raise MobileBackup2Error, "Mobile backup error: #{err}" if err != :SUCCESS

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
