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
require 'time'

module Idevice
  class MobileSyncError < IdeviceLibError
  end

  # Used to synchronize data classes with a device and computer.
  class MobileSyncClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C::Freelock.synchronize do
        unless ptr.null?
          C.mobilesync_client_free(ptr)
        end
      end
    end

    def self.attach(opts={})
        _attach_helper("com.apple.mobilesync", opts) do |idevice, ldsvc, p_ms|
        err = C.mobilesync_client_new(idevice, ldsvc, p_ms)
        raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

        ms = p_ms.read_pointer
        raise MobileSyncError, "mobilesync_client_new returned a NULL client" if ms.null?
        return new(ms)
      end
    end

    def receive_plist
      FFI::MemoryPointer.new(:pointer) do |p_result|
        err = C.mobilesync_receive(self, p_result)
        raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS
        return p_result.read_pointer.read_plist_t
      end
    end

    def send_plist(request)
      err = C.mobilesync_send(self, Plist_t.from_ruby(request))
      raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

      return true
    end

    SYNC_TYPES = [
      :FAST,  # Fast-sync requires that only the changes made since the last synchronization should be reported by the computer.
      :SLOW,  # Slow-sync requires that all data from the computer needs to be synchronized/sent.
      :RESET, # Reset-sync signals that the computer should send all data again.
    ]

    def start(data_class, anchors, data_class_version=106)
      anchors = C.mobilesync_anchors_new(*anchors)

      FFI::MemoryPointer.new(:int) do |p_sync_type|
        FFI::MemoryPointer.new(:uint64) do |p_dev_data_class_version|
          FFI::MemoryPointer.new(:pointer) do |p_error|
            err = C.mobilesync_send(self, data_class, anchors, data_class_version, p_sync_type, p_dev_data_class_version, p_error)
            errstr = nil
            p_errstr = p_error.read_pointer
            unless p_errstr.null?
              errstr = p_errstr.read_string
              C.free(p_errstr)
            end

            if err != :SUCCESS
              msg = "MobileSync error: #{err}"
              msg << "(#{errstr})" if errstr
              raise MobileSyncError, msg
            end

            sync_type = sync_type.read_int
            ddc_ver = p_device_data_class_version.read_uint64

            return({
              sync_type: (SYNC_TYPES[sync_type] || sync_type),
              device_data_class_version: ddc_ver,
              error: errstr,
            })
          end
        end
      end
    end

    def cancel(reason)
      err = C.mobilesync_cancel(self, reason)
      raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

      return true
    end

    def finish
      err = C.mobilesync_finish(self)
      raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

      return true
    end

    def request_all_records_from_device
      err = C.mobilesync_get_all_records_from_device(self)
      raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

      return true
    end

    def request_changes_from_device
      err = C.mobilesync_get_changes_from_device(self)
      raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

      return true
    end

    def clear_all_records_on_device
      err = C.mobilesync_clear_all_records_on_device(self)
      raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

      return true
    end

    def receive_changes
      ret = []

      FFI::MemoryPointer.new(:pointer) do |p_entities|
        FFI::MemoryPointer.new(:uint8) do |p_is_last_record|
          FFI::MemoryPointer.new(:pointer) do |p_actions|
            last_record = false
            until last_record
              err = C.mobilesync_receive_changes(self, p_entities, p_is_last_record, p_actions)
              raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

              last_record = (p_is_last_record.read_uint8 != 0)
              ret << {
                entities: p_entities.read_pointer.read_plist_t,
                actions:  p_actions.read_pointer.read_plist_t,
              }
            end
          end
        end
      end

      return ret
    end

    def acknowledge_changes_from_device
      err = C.mobilesync_acknowledge_changes_from_device(self)
      raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

      return true
    end

    def signal_ready_to_send_changes_from_computer
      err = C.mobilesync_ready_to_send_changes_from_computer(self)
      raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS

      return true
    end

    def _send_changes(entities, is_last, actions=nil)
      act = actions ? Plist_t.from_ruby(actions) : nil
      err = C.mobilesync_send_changes(self, Plist_t.from_ruby(entities), is_last, act)
      raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS
    end

    def send_changes(changes)
      raise TypeError, "changes must be an array" unless changes.is_a? Array
      raise ArgumentError, "changes must not be empty" if changes.empty?

      lastchange = changes.unshift
      changes.each { |change| _send_changes(change[:entities], 0, change[:actions]) }
      _send_changes(lastchange[:entities], 1, lastchange[:actions])
      return true
    end

    #mobilesync_error_t mobilesync_remap_identifiers(mobilesync_client_t client, plist_t *mapping);
    def remap_identifiers(mappings)
      raise TypeError, "mappings must be an array" unless changes.is_a? Array
      raise ArgumentError, "mappings must not be empty" if changes.empty?

      FFI::MemoryPointer.new(FFI::Pointer.size * (mappings.count+1)) do |p_mapping|
        p_mapping.write_array_of_pointer(mappings.map{|m| Plist_t.from_ruby(m)} + nil)
        err = C.mobilesync_remap_identifiers(self, p_mapping)
        raise MobileSyncError, "MobileSync error: #{err}" if err != :SUCCESS
        return true
      end
    end
  end

  # Mobile Sync anchors used by the device and computer
  class MobileSyncAnchors < FFI::ManagedStruct
    def self.release(ptr)
      C.mobilesync_anchors_free(ptr) unless ptr.null?
    end

    layout(
      :device_anchor,   :string,
      :computer_anchor, :string,
    )
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS        ,       0,
      :INVALID_ARG    ,      -1,
      :PLIST_ERROR    ,      -2,
      :MUX_ERROR      ,      -3,
      :BAD_VERSION    ,      -4,
      :SYNC_REFUSED   ,      -5,
      :CANCELLED      ,      -6,
      :WRONG_DIRECTION,      -7,
      :NOT_READY      ,      -8,
      :UNKNOWN_ERROR  ,    -256,
    ), :mobilesync_error_t

    ## The sync type of the current sync session.
    typedef enum(
      :FAST, # Fast-sync requires that only the changes made since the last synchronization should be reported by the computer.
      :SLOW, # Slow-sync requires that all data from the computer needs to be synchronized/sent.
      :RESET, # Reset-sync signals that the computer should send all data again.
    ), :mobilesync_sync_type_t

    #mobilesync_error_t mobilesync_client_new(idevice_t device, lockdownd_service_descriptor_t service, mobilesync_client_t * client);
    attach_function :mobilesync_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :mobilesync_error_t

    #mobilesync_error_t mobilesync_client_free(mobilesync_client_t client);
    attach_function :mobilesync_client_free, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_receive(mobilesync_client_t client, plist_t *plist);
    attach_function :mobilesync_receive, [MobileSyncClient, :pointer], :mobilesync_error_t

    #mobilesync_error_t mobilesync_send(mobilesync_client_t client, plist_t plist);
    attach_function :mobilesync_send, [MobileSyncClient, Plist_t], :mobilesync_error_t

    #mobilesync_error_t mobilesync_start(mobilesync_client_t client, const char *data_class, mobilesync_anchors_t anchors, uint64_t computer_data_class_version, mobilesync_sync_type_t *sync_type, uint64_t *device_data_class_version, char** error_description);
    attach_function :mobilesync_start, [MobileSyncClient, :string, MobileSyncAnchors, :uint64, :pointer, :pointer, :pointer], :mobilesync_error_t

    #mobilesync_error_t mobilesync_cancel(mobilesync_client_t client, const char* reason);
    attach_function :mobilesync_cancel, [MobileSyncClient, :string], :mobilesync_error_t

    #mobilesync_error_t mobilesync_finish(mobilesync_client_t client);
    attach_function :mobilesync_finish, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_get_all_records_from_device(mobilesync_client_t client);
    attach_function :mobilesync_get_all_records_from_device, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_get_changes_from_device(mobilesync_client_t client);
    attach_function :mobilesync_get_changes_from_device, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_clear_all_records_on_device(mobilesync_client_t client);
    attach_function :mobilesync_clear_all_records_on_device, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_receive_changes(mobilesync_client_t client, plist_t *entities, uint8_t *is_last_record, plist_t *actions);
    attach_function :mobilesync_receive_changes, [MobileSyncClient, :pointer, :pointer, :pointer], :mobilesync_error_t

    #mobilesync_error_t mobilesync_acknowledge_changes_from_device(mobilesync_client_t client);
    attach_function :mobilesync_acknowledge_changes_from_device, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_ready_to_send_changes_from_computer(mobilesync_client_t client);
    attach_function :mobilesync_ready_to_send_changes_from_computer, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_send_changes(mobilesync_client_t client, plist_t entities, uint8_t is_last_record, plist_t actions);
    attach_function :mobilesync_send_changes, [MobileSyncClient, Plist_t, :uint8, Plist_t], :mobilesync_error_t

    #mobilesync_error_t mobilesync_remap_identifiers(mobilesync_client_t client, plist_t *mapping);
    attach_function :mobilesync_remap_identifiers, [MobileSyncClient, :pointer], :mobilesync_error_t

    #mobilesync_anchors_t mobilesync_anchors_new(const char *device_anchor, const char *computer_anchor);
    attach_function :mobilesync_anchors_new, [:string, :string], MobileSyncAnchors

    #void mobilesync_anchors_free(mobilesync_anchors_t anchors);
    attach_function :mobilesync_anchors_free, [MobileSyncAnchors], :void


    ### actions Helpers

    #plist_t mobilesync_actions_new();
    attach_function :mobilesync_actions_new, [], Plist_t

    #void mobilesync_actions_add(plist_t actions, ...);
    attach_function :mobilesync_actions_add, [Plist_t, :varargs], Plist_t

    #void mobilesync_actions_free(plist_t actions);
    attach_function :mobilesync_actions_free, [Plist_t], :void

  end
end
