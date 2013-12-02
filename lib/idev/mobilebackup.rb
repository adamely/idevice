require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class MobileBackupError < IdeviceLibError
  end

  def self._handle_mb_error(&block)
    err = block.call
    if err != :SUCCESS
      raise MobileBackupError, "Mobile backup error: #{err}"
    end
  end

  class MobileBackupClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.mobilebackup_client_free(ptr) unless ptr.null?
    end

    FLAG_RESTORE_NOTIFY_SPRINGBOARD     = (1 << 0)
    FLAG_RESTORE_PRESERVE_SETTINGS      = (1 << 1)
    FLAG_RESTORE_PRESERVE_CAMERA_ROLL   = (1 << 2)

    def self.attach(opts={})
      _attach_helper("com.apple.mobilebackup", opts) do |idevice, ldsvc, p_mb|
        Idev._handle_mb_error{ C.mobilebackup_client_new(idevice, ldsvc, p_mb) }
        mb = p_mb.read_pointer
        raise MisAgentError, "mobilebackup_client_new returned a NULL client" if mb.null?
        return new(mb)
      end
    end

    def receive
      FFI::MemoryPointer.new(:pointer) do |p_result|
        Idev._handle_mb_error{ C.mobilebackup_receive(self, p_result) }
        result = p_result.read_pointer
        raise MobileBackupError, "mobilebackup_receive returned a NULL result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def send_request(plist_hash)
      Idev._handle_mb_error{ C.mobilebackup_send(self, plist_hash.to_plist_t) }
      return true
    end

    def request_backup(backup_manifest={})
      manifest = backup_manifest.dup

      proto_version = manifest.delete(:proto_version) || '1.6'
      base_path = manifest.delete(:base_path)
      raise ArgumentError, "The manifest must contain a :base_path key and value" if base_path.nil?

      Idev._handle_mb_error{ C.mobilebackup_request_backup(self, manifest.to_plist_t, base_path, proto_version) }
      return true
    end

    def send_backup_file_received
      Idev._handle_mb_error{ C.mobilebackup_send_backup_file_received(self) }
      return true
    end

    def request_restore(backup_manifest={})
      manifest = backup_manifest.dup

      proto_version = manifest.delete(:proto_version) || '1.6'
      restore_flags = manifest.delete(:restore_flags) || 0

      Idev._handle_mb_error{ C.mobilebackup_request_restore(self, manifest.to_plist_t, restore_flags, proto_version) }
      return true
    end

    def receive_restore_file_received
      FFI::MemoryPointer.new(:pointer) do |p_result|
        Idev._handle_mb_error{ C.mobilebackup_receive_restore_file_received(self, p_result) }
        result = p_result.read_pointer
        raise MobileBackupError, "mobilebackup_receive returned a NULL result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def receive_restore_application_received
      FFI::MemoryPointer.new(:pointer) do |p_result|
        Idev._handle_mb_error{ C.mobilebackup_receive_restore_application_received(self, p_result) }
        result = p_result.read_pointer
        raise MobileBackupError, "mobilebackup_receive returned a NULL result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def send_restore_complete
      Idev._handle_mb_error{ C.mobilebackup_send_restore_complete(self) }
      return true
    end

    def send_error(reason)
      Idev._handle_mb_error{ C.mobilebackup_send_error(self, reason) }
      return true
    end
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS      ,         0,
      :INVALID_ARG  ,        -1,
      :PLIST_ERROR  ,        -2,
      :MUX_ERROR    ,        -3,
      :BAD_VERSION  ,        -4,
      :REPLY_NOT_OK ,        -5,
      :UNKNOWN_ERROR,      -256,
    ), :mobilebackup_error_t

    typedef :int, :mobilebackup_flags_t

    #mobilebackup_error_t mobilebackup_client_new(idevice_t device, lockdownd_service_descriptor_t service, mobilebackup_client_t * client);
    attach_function :mobilebackup_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_client_free(mobilebackup_client_t client);
    attach_function :mobilebackup_client_free, [MobileBackupClient], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_receive(mobilebackup_client_t client, plist_t *plist);
    attach_function :mobilebackup_receive, [MobileBackupClient, :pointer], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_send(mobilebackup_client_t client, plist_t plist);
    attach_function :mobilebackup_send, [MobileBackupClient, Plist_t], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_request_backup(mobilebackup_client_t client, plist_t backup_manifest, const char *base_path, const char *proto_version);
    attach_function :mobilebackup_request_backup, [MobileBackupClient, Plist_t, :string, :string], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_send_backup_file_received(mobilebackup_client_t client);
    attach_function :mobilebackup_send_backup_file_received, [MobileBackupClient], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_request_restore(mobilebackup_client_t client, plist_t backup_manifest, mobilebackup_flags_t flags, const char *proto_version);
    attach_function :mobilebackup_request_restore, [MobileBackupClient, Plist_t, :mobilebackup_flags_t, :string], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_receive_restore_file_received(mobilebackup_client_t client, plist_t *result);
    attach_function :mobilebackup_receive_restore_file_received, [MobileBackupClient, :pointer], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_receive_restore_application_received(mobilebackup_client_t client, plist_t *result);
    attach_function :mobilebackup_receive_restore_application_received, [MobileBackupClient, :pointer], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_send_restore_complete(mobilebackup_client_t client);
    attach_function :mobilebackup_send_restore_complete, [MobileBackupClient], :mobilebackup_error_t

    #mobilebackup_error_t mobilebackup_send_error(mobilebackup_client_t client, const char *reason);
    attach_function :mobilebackup_send_error, [MobileBackupClient, :string], :mobilebackup_error_t

  end
end
