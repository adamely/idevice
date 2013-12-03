#
# Copyright (c) 2013 Eric Monti
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'idevice/c'
require 'idevice/plist'
require 'idevice/idevice'

module Idevice
  class LockdownError < IdeviceLibError
  end

  # Used to manage device preferences, start services, pairing and activation on the device.
  class LockdownClient < C::ManagedOpaquePointer
    def self.release(ptr)
      C.lockdownd_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      idevice = opts[:idevice] || Idevice.attach(opts)

      label = opts[:label] || "ruby-idevice"

      FFI::MemoryPointer.new(:pointer) do |p_lockdown_client|
        err =
          if opts[:nohandshake]
            C.lockdownd_client_new(idevice, p_lockdown_client, label)
          else
            C.lockdownd_client_new_with_handshake(idevice, p_lockdown_client, label)
          end

        raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS

        lockdown_client = p_lockdown_client.read_pointer
        if lockdown_client.null?
          raise LockdownError, "lockdownd_client creation returned a NULL object"
        else
          return new(lockdown_client)
        end
      end
    end

    def device_udid
      res = nil
      FFI::MemoryPointer.new(:pointer) do |p_udid|
        err = C.lockdownd_get_device_udid(self, p_udid)
        raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS

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
        err = C.lockdownd_get_device_name(self, p_name)
        raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS

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
          err = C.lockdownd_get_sync_data_classes(self, p_sync_classes, p_count)
          raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS

          sync_classes = p_sync_classes.read_pointer
          count = p_count.read_int
          unless sync_classes.null?
            res = sync_classes.read_array_of_pointer(count).map{|p| p.read_string }
            err = C.lockdownd_data_classes_free(sync_classes)
            raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
          end
        end
      end
      return res
    end

    def query_type
      res = nil
      FFI::MemoryPointer.new(:pointer) do |p_type|
        err = C.lockdownd_query_type(self, p_type)
        raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS

        type = p_type.read_pointer
        res = type.read_string
        C.free(type)
      end
      return res
    end

    def get_value(domain, key)
      res = nil
      FFI::MemoryPointer.new(:pointer) do |p_val|
        err = C.lockdownd_get_value(self, domain, key, p_val)
        raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS

        res = p_val.read_pointer.read_plist_t
      end
      return res
    end

    def set_value(domain, key, value)
      err = C.lockdownd_set_value(self, domain, key, Plist_t.from_ruby(value))
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
      return true
    end

    def remove_value(domain, key)
      err = C.lockdownd_remove_value(self, domain, key)
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
      return true
    end

    def start_service(identifier)
      ret = nil
      FFI::MemoryPointer.new(:pointer) do |p_ldsvc|
        err = C.lockdownd_start_service(self, identifier, p_ldsvc)
        raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS

        ldsvc = p_ldsvc.read_pointer
        unless ldsvc.null?
          ret = LockdownServiceDescriptor.new(ldsvc)
        end
      end
      return ret
    end

    def send_plist(obj)
      err = C.lockdownd_send(self, Plist_t.from_ruby(obj))
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS

      return true
    end

    def receive_plist
      ret = nil
      FFI::MemoryPointer.new(:pointer) do |p_plist|
        err = C.lockdownd_receive(self, p_plist)
        raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS

        ret = p_plist.read_pointer.read_plist_t
      end
      return ret
    end

    def pair(pair_record)
      raise TypeError, "pair_record must be a LockdownPairRecord" unless pair_record.is_a?(LockdownPairRecord)
      err = C.lockdownd_pair(self, pair_record)
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
      return true
    end

    def validate_pair(pair_record)
      raise TypeError, "pair_record must be a LockdownPairRecord" unless pair_record.is_a?(LockdownPairRecord)
      err = C.lockdownd_validate_pair(self, pair_record)
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
      return true
    end

    def unpair(pair_record)
      raise TypeError, "pair_record must be a LockdownPairRecord" unless pair_record.is_a?(LockdownPairRecord)
      err = C.lockdownd_unpair(self, pair_record)
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
      return true
    end

    def activate(activation_record)
      err = C.lockdownd_activate(self, Plist_t.from_ruby(activation_record))
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
      return true
    end

    def deactivate
      err = C.lockdownd_deactivate(self)
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
      return true
    end

    def enter_recovery
      err = C.lockdownd_enter_recovery(self)
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
      return true
    end

    def goodbye
      err = C.lockdownd_goodbye(self)
      raise LockdownError, "Lockdownd error: #{err}" if err != :SUCCESS
      return true
    end

    def set_label(label)
      C.lockdownd_client_set_label(self, label)
      return true
    end
  end

  class LockdownPairRecord < FFI::Struct
    layout(
      :device_certificate,  :string,
      :host_certificate,    :string,
      :host_id,             :string,
      :root_certificate,    :string,
    )
  end

  class LockdownServiceDescriptor < FFI::ManagedStruct
    layout(
      :port,                :uint16,
      :ssl_enabled,         :uint8,
    )

    def self.release(ptr)
      C::lockdownd_service_descriptor_free(ptr)
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

    #lockdownd_error_t lockdownd_client_new(idevice_t device, lockdownd_client_t *client, const char *label);
    attach_function :lockdownd_client_new, [Idevice, :pointer, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_client_new_with_handshake(idevice_t device, lockdownd_client_t *client, const char *label);
    attach_function :lockdownd_client_new_with_handshake, [Idevice, :pointer, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_client_free(lockdownd_client_t client);
    attach_function :lockdownd_client_free, [LockdownClient], :lockdownd_error_t

    #lockdownd_error_t lockdownd_query_type(lockdownd_client_t client, char **type);
    attach_function :lockdownd_query_type, [LockdownClient, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_get_value(lockdownd_client_t client, const char *domain, const char *key, plist_t *value);
    attach_function :lockdownd_get_value, [LockdownClient, :string, :string, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_set_value(lockdownd_client_t client, const char *domain, const char *key, plist_t value);
    attach_function :lockdownd_set_value, [LockdownClient, :string, :string, Plist_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_remove_value(lockdownd_client_t client, const char *domain, const char *key);
    attach_function :lockdownd_remove_value, [LockdownClient, :string, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_start_service(lockdownd_client_t client, const char *identifier, lockdownd_service_descriptor_t *service);
    attach_function :lockdownd_start_service, [LockdownClient, :string, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_start_session(lockdownd_client_t client, const char *host_id, char **session_id, int *ssl_enabled);
    attach_function :lockdownd_start_session, [LockdownClient, :string, :pointer, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_stop_session(lockdownd_client_t client, const char *session_id);
    attach_function :lockdownd_stop_session, [LockdownClient, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_send(lockdownd_client_t client, plist_t plist);
    attach_function :lockdownd_send, [LockdownClient, Plist_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_receive(lockdownd_client_t client, plist_t *plist);
    attach_function :lockdownd_receive, [LockdownClient, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_pair(lockdownd_client_t client, lockdownd_pair_record_t pair_record);
    attach_function :lockdownd_pair, [LockdownClient, LockdownPairRecord], :lockdownd_error_t

    #lockdownd_error_t lockdownd_validate_pair(lockdownd_client_t client, lockdownd_pair_record_t pair_record);
    attach_function :lockdownd_validate_pair, [LockdownClient, LockdownPairRecord], :lockdownd_error_t

    #lockdownd_error_t lockdownd_unpair(lockdownd_client_t client, lockdownd_pair_record_t pair_record);
    attach_function :lockdownd_unpair, [LockdownClient, LockdownPairRecord], :lockdownd_error_t

    #lockdownd_error_t lockdownd_activate(lockdownd_client_t client, plist_t activation_record);
    attach_function :lockdownd_activate, [LockdownClient, Plist_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_deactivate(lockdownd_client_t client);
    attach_function :lockdownd_deactivate, [LockdownClient], :lockdownd_error_t

    #lockdownd_error_t lockdownd_enter_recovery(lockdownd_client_t client);
    attach_function :lockdownd_enter_recovery, [LockdownClient], :lockdownd_error_t

    #lockdownd_error_t lockdownd_goodbye(lockdownd_client_t client);
    attach_function :lockdownd_goodbye, [LockdownClient], :lockdownd_error_t

    #void lockdownd_client_set_label(lockdownd_client_t client, const char *label);
    attach_function :lockdownd_client_set_label, [LockdownClient, :string], :void

    #lockdownd_error_t lockdownd_get_device_udid(lockdownd_client_t control, char **udid);
    attach_function :lockdownd_get_device_udid, [LockdownClient, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_get_device_name(lockdownd_client_t client, char **device_name);
    attach_function :lockdownd_get_device_name, [LockdownClient, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_get_sync_data_classes(lockdownd_client_t client, char ***classes, int *count);
    attach_function :lockdownd_get_sync_data_classes, [LockdownClient, :pointer, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_data_classes_free(char **classes);
    attach_function :lockdownd_data_classes_free, [:pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_service_descriptor_free(lockdownd_service_descriptor_t service);
    attach_function :lockdownd_service_descriptor_free, [LockdownServiceDescriptor], :lockdownd_error_t
  end
end
