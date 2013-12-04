#
# Copyright (c) 2013 Eric Monti - Bluebox Security
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'idevice/c'
require 'idevice/plist'
require 'idevice/idevice'
require 'idevice/lockdown'

module Idevice
  class MisAgentError < IdeviceLibError
  end

  # Used to manage provisioning profiles on the device.
  class MisAgentClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C::Freelock.synchronize do
        unless ptr.null?
          C.misagent_client_free(ptr)
        end
      end
    end

    def self.attach(opts={})
      _attach_helper("com.apple.misagent", opts) do |idevice, ldsvc, p_ma|
        err = C.misagent_client_new(idevice, ldsvc, p_ma)
        raise MisAgentError, "misagent error: #{err}" if err != :SUCCESS

        ma = p_ma.read_pointer
        raise MisAgentError, "misagent_client_new returned a NULL misagent_client_t pointer" if ma.null?
        return new(ma)
      end
    end

    def status_code
      C.misagent_get_status_code(self)
    end

    def profiles
      FFI::MemoryPointer.new(:pointer) do |p_profiles|
        err = C.misagent_copy(self, p_profiles)
        raise MisAgentError, "misagent error: #{err}" if err != :SUCCESS

        profiles = p_profiles.read_pointer.read_plist_t
        raise MisAgentError, "misagent_copy returned null profiles plist_t" if profiles.nil?
        return profiles
      end
    end

    def install(profile_hash)
      err = C.misagent_install(self, Plist_t.from_ruby(profile_hash))
      raise MisAgentError, "misagent error: #{err}" if err != :SUCCESS

      return status_code
    end

    def remove(profile_ident)
      err = C.misagent_remove(self, profile_ident)
      raise MisAgentError, "misagent error: #{err}" if err != :SUCCESS

      return status_code
    end

  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS        ,       0,
      :INVALID_ARG    ,      -1,
      :PLIST_ERROR    ,      -2,
      :CONN_FAILED    ,      -3,
      :REQUEST_FAILED ,      -4,
      :UNKNOWN_ERROR  ,    -256,
    ), :misagent_error_t


    #misagent_error_t misagent_client_new(idevice_t device, lockdownd_service_descriptor_t service, misagent_client_t *client);
    attach_function :misagent_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :misagent_error_t

    #misagent_error_t misagent_client_free(misagent_client_t client);
    attach_function :misagent_client_free, [MisAgentClient], :misagent_error_t

    #misagent_error_t misagent_install(misagent_client_t client, plist_t profile);
    attach_function :misagent_install, [MisAgentClient, Plist_t], :misagent_error_t

    #misagent_error_t misagent_copy(misagent_client_t client, plist_t* profiles);
    attach_function :misagent_copy, [MisAgentClient, :pointer], :misagent_error_t

    #misagent_error_t misagent_remove(misagent_client_t client, const char* profileID);
    attach_function :misagent_remove, [MisAgentClient, :string], :misagent_error_t

    #int misagent_get_status_code(misagent_client_t client);
    attach_function :misagent_get_status_code, [MisAgentClient], :int

  end
end
