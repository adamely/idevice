require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class RestoreErrror < IdeviceLibError
  end

  def self._handle_restore_error(&block)
    err = block.call
    if err != :SUCCESS
      raise RestoreErrror, "Restore Error: #{err}"
    end
  end

  # Used to initiate the device restore process or reboot a device.
  class RestoreClient < C::ManagedOpaquePointer
    def self.release(ptr)
      C.restored_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      idevice = opts[:idevice] || Idevice.attach(opts)
      label = opts[:label] || "ruby-idev"

      FFI::MemoryPointer.new(:pointer) do |p_rc|
        Idev._handle_restore_error{ C.restored_client_new(idevice, p_rc, label) }
        rc = p_rc.read_pointer
        raise NPError, "restore_client_new returned a NULL client" if rc.null?
        return new(rc)
      end
    end

    def goodbye
      Idev._handle_restore_error{ C.restored_goodbye(self) }
      return true
    end

    def query_type
      FFI::MemoryPointer.new(:pointer) do |p_type|
        FFI::MemoryPointer.new(:uint64) do |p_vers|
          Idev._handle_restore_error{ C.restored_query_type(self, p_type, p_vers) }
          type = p_type.read_pointer
          raise RestoreErrror, "restored_query_type returned a null type" if type.null?
          result = {
            type: type.read_string,
            version: p_vers.read_uint64,
          }
          C.free(type)
          return result
        end
      end
    end

    def query_value(key)
      FFI::MemoryPointer.new(:pointer) do |p_value|
        Idev._handle_restore_error{ C.restored_query_value(self, key, p_value) }
        value = p_value.read_pointer
        if value
          return Plist_t.new(value).to_ruby
        end
      end
    end

    def get_value(key)
      FFI::MemoryPointer.new(:pointer) do |p_value|
        Idev._handle_restore_error{ C.restored_get_value(self, key, p_value) }
        value = p_value.read_pointer
        if value
          return Plist_t.new(value).to_ruby
        end
      end
    end

    def send_plist(dict)
      Idev._handle_restore_error{ C.restored_send(self, hash.to_plist_t) }
    end

    def receive_plist
      FFI::MemoryPointer.new(:pointer) do |p_value|
        Idev._handle_restore_error{ C.restored_receive(self, p_value) }
        value = p_value.read_pointer
        if value
          return Plist_t.new(value).to_ruby
        end
      end
    end

    def start_restore(version, options={})
      Idev._handle_restore_error{ C.restored_start_restore(self, options.to_plist_t, version) }
      return true
    end

    def reboot
      Idev._handle_restore_error{ C.restored_reboot(self) }
      return true
    end

    def set_label(label)
      C.restored_client_set_label(self, label)
      return true
    end

  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS             ,       0,
      :INVALID_ARG         ,      -1,
      :INVALID_CONF        ,      -2,
      :PLIST_ERROR         ,      -3,
      :DICT_ERROR          ,      -4,
      :NOT_ENOUGH_DATA     ,      -5,
      :MUX_ERROR           ,      -6,
      :START_RESTORE_FAILED,      -7,
      :UNKNOWN_ERROR       ,    -256,
    ), :restored_error_t

    #restored_error_t restored_client_new(idevice_t device, restored_client_t *client, const char *label);
    attach_function :restored_client_new, [Idevice, :pointer, :string], :restored_error_t

    #restored_error_t restored_client_free(restored_client_t client);
    attach_function :restored_client_free, [RestoreClient], :restored_error_t

    #restored_error_t restored_query_type(restored_client_t client, char **type, uint64_t *version);
    attach_function :restored_query_type, [RestoreClient, :pointer, :pointer], :restored_error_t

    #restored_error_t restored_query_value(restored_client_t client, const char *key, plist_t *value);
    attach_function :restored_query_value, [RestoreClient, :string, :pointer], :restored_error_t

    #restored_error_t restored_get_value(restored_client_t client, const char *key, plist_t *value) ;
    attach_function :restored_get_value, [RestoreClient, :string, :pointer], :restored_error_t

    #restored_error_t restored_send(restored_client_t client, plist_t plist);
    attach_function :restored_send, [RestoreClient, Plist_t], :restored_error_t

    #restored_error_t restored_receive(restored_client_t client, plist_t *plist);
    attach_function :restored_receive, [RestoreClient, :pointer], :restored_error_t

    #restored_error_t restored_goodbye(restored_client_t client);
    attach_function :restored_goodbye, [RestoreClient], :restored_error_t

    #restored_error_t restored_start_restore(restored_client_t client, plist_t options, uint64_t version);
    attach_function :restored_start_restore, [RestoreClient, Plist_t, :uint64], :restored_error_t

    #restored_error_t restored_reboot(restored_client_t client);
    attach_function :restored_reboot, [RestoreClient], :restored_error_t

    #void restored_client_set_label(restored_client_t client, const char *label);
    attach_function :restored_client_set_label, [RestoreClient, :string], :void

  end
end
