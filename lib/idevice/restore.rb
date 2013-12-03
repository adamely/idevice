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
require 'idevice/lockdown'

module Idevice
  class RestoreErrror < IdeviceLibError
  end

  # Used to initiate the device restore process or reboot a device.
  class RestoreClient < C::ManagedOpaquePointer
    def self.release(ptr)
      C.restored_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      idevice = opts[:idevice] || Idevice.attach(opts)
      label = opts[:label] || "ruby-idevice"

      FFI::MemoryPointer.new(:pointer) do |p_rc|
        err = C.restored_client_new(idevice, p_rc, label)
        raise RestoreErrror, "Restore Error: #{err}" if err != :SUCCESS

        rc = p_rc.read_pointer
        raise NPError, "restore_client_new returned a NULL client" if rc.null?
        return new(rc)
      end
    end

    def goodbye
      err = C.restored_goodbye(self)
      raise RestoreErrror, "Restore Error: #{err}" if err != :SUCCESS

      return true
    end

    def query_type
      FFI::MemoryPointer.new(:pointer) do |p_type|
        FFI::MemoryPointer.new(:uint64) do |p_vers|
          err = C.restored_query_type(self, p_type, p_vers)
          raise RestoreErrror, "Restore Error: #{err}" if err != :SUCCESS

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
        err = C.restored_query_value(self, key, p_value)
        raise RestoreErrror, "Restore Error: #{err}" if err != :SUCCESS

        return p_value.read_pointer.read_plist_t
      end
    end

    def get_value(key)
      FFI::MemoryPointer.new(:pointer) do |p_value|
        err = C.restored_get_value(self, key, p_value)
        raise RestoreErrror, "Restore Error: #{err}" if err != :SUCCESS
        return p_value.read_pointer.read_plist_t
      end
    end

    def send_plist(dict)
      err = C.restored_send(self, Plist_t.from_ruby(hash))
      raise RestoreErrror, "Restore Error: #{err}" if err != :SUCCESS

    end

    def receive_plist
      FFI::MemoryPointer.new(:pointer) do |p_value|
        err = C.restored_receive(self, p_value)
        raise RestoreErrror, "Restore Error: #{err}" if err != :SUCCESS
        return p_value.read_pointer.read_plist_t
      end
    end

    def start_restore(version, options={})
      err = C.restored_start_restore(self, Plist_t.from_ruby(options), version)
      raise RestoreErrror, "Restore Error: #{err}" if err != :SUCCESS

      return true
    end

    def reboot
      err = C.restored_reboot(self)
      raise RestoreErrror, "Restore Error: #{err}" if err != :SUCCESS

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
