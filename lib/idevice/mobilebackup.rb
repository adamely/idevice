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
  class MobileBackupError < IdeviceLibError
  end

  # Used to backup and restore of all device data. (Pre iOS 4)
  class MobileBackupClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C::Freelock.synchronize do
        unless ptr.null?
          C.mobilebackup_client_free(ptr)
        end
      end
    end

    FLAG_RESTORE_NOTIFY_SPRINGBOARD     = (1 << 0)
    FLAG_RESTORE_PRESERVE_SETTINGS      = (1 << 1)
    FLAG_RESTORE_PRESERVE_CAMERA_ROLL   = (1 << 2)

    def self.attach(opts={})
      _attach_helper("com.apple.mobilebackup", opts) do |idevice, ldsvc, p_mb|
        err = C.mobilebackup_client_new(idevice, ldsvc, p_mb)
        raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

        mb = p_mb.read_pointer
        raise MisAgentError, "mobilebackup_client_new returned a NULL client" if mb.null?
        return new(mb)
      end
    end

    def receive_plist
      FFI::MemoryPointer.new(:pointer) do |p_result|
        err = C.mobilebackup_receive(self, p_result)
        raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

        return p_result.read_pointer.read_plist_t
      end
    end

    def send_plist(dict)
      err = C.mobilebackup_send(self, Plist_t.from_ruby(dict))
      raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

      return true
    end

    def request_backup(backup_manifest={})
      manifest = backup_manifest.dup

      proto_version = manifest.delete(:proto_version) || '1.6'
      base_path = manifest.delete(:base_path)
      raise ArgumentError, "The manifest must contain a :base_path key and value" if base_path.nil?

      err = C.mobilebackup_request_backup(self, Plist_t.from_ruby(manifest), base_path, proto_version)
      raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

      return true
    end

    def send_backup_file_received
      err = C.mobilebackup_send_backup_file_received(self)
      raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

      return true
    end

    def request_restore(backup_manifest={})
      manifest = backup_manifest.dup

      proto_version = manifest.delete(:proto_version) || '1.6'
      restore_flags = manifest.delete(:restore_flags) || 0

      err = C.mobilebackup_request_restore(self, Plist_t.from_ruby(manifest), restore_flags, proto_version)
      raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

      return true
    end

    def receive_restore_file_received
      FFI::MemoryPointer.new(:pointer) do |p_result|
        err = C.mobilebackup_receive_restore_file_received(self, p_result)
        raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

        return p_result.read_pointer.read_plist_t
      end
    end

    def receive_restore_application_received
      FFI::MemoryPointer.new(:pointer) do |p_result|
        err = C.mobilebackup_receive_restore_application_received(self, p_result)
        raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

        return p_result.read_pointer.read_plist_t
      end
    end

    def send_restore_complete
      err = C.mobilebackup_send_restore_complete(self)
      raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

      return true
    end

    def send_error(reason)
      err = C.mobilebackup_send_error(self, reason)
      raise MobileBackupError, "Mobile backup error: #{err}" if err != :SUCCESS

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
