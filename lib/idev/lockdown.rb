require 'idev/c'
require 'idev/plist'
require 'idev/idevice'

module Idev
  class LockdownClient
    attr_reader :idevice

    def initialize(opts={})
      @idevice = Idevice.attach(opts[:udid])

      label = opts[:label] || "ruby-idev"

      FFI::MemoryPointer.new(:pointer) do |p_lockdown_client|
        _handle_lockdown_error do
          if opts[:nohandshake]
            C.lockdownd_client_new(@idevice, p_lockdown_client, label)
          else
            C.lockdownd_client_new_with_handshake(@idevice, p_lockdown_client, label)
          end
        end

        @_lockdown_client_ptr = p_lockdown_client.read_pointer
      end
    end

    def destroy_lockdown_client
      _handle_lockdown_error{ C.lockdownd_client_free(_lockdown_client_ptr) }
      @_lockdown_client_ptr = nil
    end

    def destroy
      _destroy_lockdown_client
      @idevice = nil
    end

    def ready?
      not destroyed?
    end

    def destroyed?
      @_lockdown_client_ptr.nil?
    end

    def device_udid
      res = nil
      FFI::MemoryPointer.new(:pointer) do |p_udid|
        _handle_lockdown_error{ C.lockdownd_get_device_udid(_lockdown_client_ptr, p_udid) }
        udid = p_udid.read_pointer
        unless udid.null?
          res = udid.read_string
          C.free(udid)
        end
      end
      return res
    end

    def device_name
      res = nil
      FFI::MemoryPointer.new(:pointer) do |p_name|
        _handle_lockdown_error{ C.lockdownd_get_device_name(_lockdown_client_ptr, p_name) }
        name = p_name.read_pointer
        unless name.null?
          res = name.read_string
          C.free(name)
        end
      end
      return res
    end

    def sync_data_classes
      res = nil
      FFI::MemoryPointer.new(:pointer) do |p_sync_classes|
        FFI::MemoryPointer.new(:int) do |p_count|
          _handle_lockdown_error{ C.lockdownd_get_sync_data_classes(_lockdown_client_ptr, p_sync_classes, p_count) }
          sync_classes = p_sync_classes.read_pointer
          count = p_count.read_int
          unless sync_classes.null?
            res = sync_classes.read_array_of_pointer(count).map{|p| p.read_string }
            _handle_lockdown_error{ C.lockdownd_data_classes_free(sync_classes) }
          end
        end
      end
      return res
    end

    def query_type
      res = nil
      FFI::MemoryPointer.new(:pointer) do |p_type|
        _handle_lockdown_error{ C.lockdownd_query_type(_lockdown_client_ptr, p_type) }
        type = p_type.read_pointer
        res = type.read_string
        C.free(type)
      end
      return res
    end

    def get_value(domain, key)
      res = nil
      FFI::MemoryPointer.new(:pointer) do |p_val|
        _handle_lockdown_error{ C.lockdownd_get_value(_lockdown_client_ptr, domain, key, p_val) }
        pl = Plist_t.new(p_val.read_pointer)
        unless pl.null?
          res = pl.to_ruby
        end
      end
      return res
    end

    def set_value(domain, key)
      # XXX TODO
      raise NotImplementedError
    end

    def remove_value(domain, key)
      # XXX TODO
      raise NotImplementedError
    end

    def start_service(identifier)
      FFI::MemoryPointer.new(:pointer) do |p_ldsvc|
        _handle_lockdown_error{ C.lockdownd_start_service(_lockdown_client_ptr, identifier, p_ldsvc) }
        ldsvc = p_ldsvc.read_pointer
        unless ldsvc.null?
          return C::LockdowndServiceDescriptor.new(ldsvc)
        end
      end
      return nil
    end

    private
    def _lockdown_client_ptr
      return @_lockdown_client_ptr if @_lockdown_client_ptr
      raise "lockdown client not initialized"
    end

    def _handle_lockdown_error
      err = yield
      if err != :SUCCESS
        raise IdeviceLibError, "Lockdownd error: #{err}"
      end
    end
  end

  class LockdownServiceClient
    def initialize(svc_identifier, opts={})
      lockdown_client = LockdownClient.new(opts)
      @_lockdown_service_descriptor = lockdown_client.start_service(svc_identifier)
      @_idevice = lockdown_client.idevice
      lockdown_client.destroy_lockdown_client
    end
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS                  ,  0,
      :INVALID_ARG              , -1,
      :INVALID_CONF             , -2,
      :PLIST_ERROR              , -3,
      :PAIRING_FAILED           , -4,
      :SSL_ERROR                , -5,
      :DICT_ERROR               , -6,
      :START_SERVICE_FAILED     , -7,
      :NOT_ENOUGH_DATA          , -8,
      :SET_VALUE_PROHIBITED     , -9,
      :GET_VALUE_PROHIBITED     ,-10,
      :REMOVE_VALUE_PROHIBITED  ,-11,
      :MUX_ERROR                ,-12,
      :ACTIVATION_FAILED        ,-13,
      :PASSWORD_PROTECTED       ,-14,
      :NO_RUNNING_SESSION       ,-15,
      :INVALID_HOST_ID          ,-16,
      :INVALID_SERVICE          ,-17,
      :INVALID_ACTIVATION_RECORD,-18,
      :UNKNOWN_ERROR            ,-256,
    ), :lockdownd_error_t

    typedef :pointer, :lockdownd_client_t

    class LockdowndPairRecord < FFI::Struct
      layout( :device_certificate,    :string,
              :host_certificate,      :string,
              :host_id,               :string,
              :root_certificate,      :string )
    end

    class LockdowndServiceDescriptor < FFI::ManagedStruct
      layout( :port,        :uint16,
              :ssl_enabled, :uint8 )

      def self.release(ptr)
        C::lockdownd_service_descriptor_free(ptr)
      end
    end

    #lockdownd_error_t lockdownd_client_new(idevice_t device, lockdownd_client_t *client, const char *label);
    attach_function :lockdownd_client_new, [Idevice, :pointer, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_client_new_with_handshake(idevice_t device, lockdownd_client_t *client, const char *label);
    attach_function :lockdownd_client_new_with_handshake, [Idevice, :pointer, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_client_free(lockdownd_client_t client);
    attach_function :lockdownd_client_free, [:lockdownd_client_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_query_type(lockdownd_client_t client, char **type);
    attach_function :lockdownd_query_type, [:lockdownd_client_t, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_get_value(lockdownd_client_t client, const char *domain, const char *key, plist_t *value);
    attach_function :lockdownd_get_value, [:lockdownd_client_t, :string, :string, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_set_value(lockdownd_client_t client, const char *domain, const char *key, plist_t value);
    attach_function :lockdownd_set_value, [:lockdownd_client_t, :string, :string, Plist_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_remove_value(lockdownd_client_t client, const char *domain, const char *key);
    attach_function :lockdownd_remove_value, [:lockdownd_client_t, :string, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_start_service(lockdownd_client_t client, const char *identifier, lockdownd_service_descriptor_t *service);
    attach_function :lockdownd_start_service, [:lockdownd_client_t, :string, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_start_session(lockdownd_client_t client, const char *host_id, char **session_id, int *ssl_enabled);
    attach_function :lockdownd_start_session, [:lockdownd_client_t, :string, :pointer, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_stop_session(lockdownd_client_t client, const char *session_id);
    attach_function :lockdownd_stop_session, [:lockdownd_client_t, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_send(lockdownd_client_t client, plist_t plist);
    attach_function :lockdownd_send, [:lockdownd_client_t, Plist_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_receive(lockdownd_client_t client, plist_t *plist);
    attach_function :lockdownd_receive, [:lockdownd_client_t, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_pair(lockdownd_client_t client, lockdownd_pair_record_t pair_record);
    attach_function :lockdownd_pair, [:lockdownd_client_t, LockdowndPairRecord], :lockdownd_error_t

    #lockdownd_error_t lockdownd_validate_pair(lockdownd_client_t client, lockdownd_pair_record_t pair_record);
    attach_function :lockdownd_validate_pair, [:lockdownd_client_t, LockdowndPairRecord], :lockdownd_error_t

    #lockdownd_error_t lockdownd_unpair(lockdownd_client_t client, lockdownd_pair_record_t pair_record);
    attach_function :lockdownd_unpair, [:lockdownd_client_t, LockdowndPairRecord], :lockdownd_error_t

    #lockdownd_error_t lockdownd_activate(lockdownd_client_t client, plist_t activation_record);
    attach_function :lockdownd_activate, [:lockdownd_client_t, Plist_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_deactivate(lockdownd_client_t client);
    attach_function :lockdownd_deactivate, [:lockdownd_client_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_enter_recovery(lockdownd_client_t client);
    attach_function :lockdownd_enter_recovery, [:lockdownd_client_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_goodbye(lockdownd_client_t client);
    attach_function :lockdownd_goodbye, [:lockdownd_client_t], :lockdownd_error_t

    #void lockdownd_client_set_label(lockdownd_client_t client, const char *label);
    attach_function :lockdownd_client_set_label, [:lockdownd_client_t, :string], :void

    #lockdownd_error_t lockdownd_get_device_udid(lockdownd_client_t control, char **udid);
    attach_function :lockdownd_get_device_udid, [:lockdownd_client_t, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_get_device_name(lockdownd_client_t client, char **device_name);
    attach_function :lockdownd_get_device_name, [:lockdownd_client_t, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_get_sync_data_classes(lockdownd_client_t client, char ***classes, int *count);
    attach_function :lockdownd_get_sync_data_classes, [:lockdownd_client_t, :pointer, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_data_classes_free(char **classes);
    attach_function :lockdownd_data_classes_free, [:pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_service_descriptor_free(lockdownd_service_descriptor_t service);
    attach_function :lockdownd_service_descriptor_free, [LockdowndServiceDescriptor], :lockdownd_error_t
  end
end
