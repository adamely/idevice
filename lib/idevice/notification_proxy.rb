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
require 'idevice/idevice'
require 'idevice/lockdown'

module Idevice
  class NotificationProxyError < IdeviceLibError
  end

  # Aliased short name for NotificationProxyError
  NPError = NotificationProxyError

  # Notifications that can be received from the device
  module NPRecvNotifications
    SYNC_CANCEL_REQUEST       = "com.apple.itunes-client.syncCancelRequest"
    SYNC_SUSPEND_REQUEST      = "com.apple.itunes-client.syncSuspendRequest"
    SYNC_RESUME_REQUEST       = "com.apple.itunes-client.syncResumeRequest"
    PHONE_NUMBER_CHANGED      = "com.apple.mobile.lockdown.phone_number_changed"
    DEVICE_NAME_CHANGED       = "com.apple.mobile.lockdown.device_name_changed"
    TIMEZONE_CHANGED          = "com.apple.mobile.lockdown.timezone_changed"
    TRUSTED_HOST_ATTACHED     = "com.apple.mobile.lockdown.trusted_host_attached"
    HOST_DETACHED             = "com.apple.mobile.lockdown.host_detached"
    HOST_ATTACHED             = "com.apple.mobile.lockdown.host_attached"
    REGISTRATION_FAILED       = "com.apple.mobile.lockdown.registration_failed"
    ACTIVATION_STATE          = "com.apple.mobile.lockdown.activation_state"
    BRICK_STATE               = "com.apple.mobile.lockdown.brick_state"
    DISK_USAGE_CHANGED        = "com.apple.mobile.lockdown.disk_usage_changed"# /**< iOS 4.0+ */
    DS_DOMAIN_CHANGED         = "com.apple.mobile.data_sync.domain_changed"
    BACKUP_DOMAIN_CHANGED     = "com.apple.mobile.backup.domain_changed"
    APP_INSTALLED             = "com.apple.mobile.application_installed"
    APP_UNINSTALLED           = "com.apple.mobile.application_uninstalled"
    DEV_IMAGE_MOUNTED         = "com.apple.mobile.developer_image_mounted"
    ATTEMPTACTIVATION         = "com.apple.springboard.attemptactivation"
    ITDBPREP_DID_END          = "com.apple.itdbprep.notification.didEnd"
    LANGUAGE_CHANGED          = "com.apple.language.changed"
    ADDRESS_BOOK_PREF_CHANGED = "com.apple.AddressBook.PreferenceChanged"
  end

  # Notifications that can be sent to the device
  module NPSendNotifications
    SYNC_WILL_START           = "com.apple.itunes-mobdev.syncWillStart"
    SYNC_DID_START            = "com.apple.itunes-mobdev.syncDidStart"
    SYNC_DID_FINISH           = "com.apple.itunes-mobdev.syncDidFinish"
    SYNC_LOCK_REQUEST         = "com.apple.itunes-mobdev.syncLockRequest"
  end

  # Used to receive and post device notifications
  class NotificationProxyClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C::Freelock.synchronize do
        unless ptr.null?
          C.np_client_free(ptr)
        end
      end
    end

    def self.attach(opts={})
      _attach_helper("com.apple.mobile.notification_proxy", opts) do |idevice, ldsvc, p_np|
        err = C.np_client_new(idevice, ldsvc, p_np)
        raise NotificationProxyError, "Notification Proxy Error: #{err}" if err != :SUCCESS

        np = p_np.read_pointer
        raise NPError, "np_client_new returned a NULL client" if np.null?
        return new(np)
      end
    end

    def post_notification(notification)
      err = C.np_post_notification(self, notification)
      raise NotificationProxyError, "Notification Proxy Error: #{err}" if err != :SUCCESS

      return true
    end

    def observe_notification(notification_type)
      err = C.np_observe_notification(self, notification_type)
      raise NotificationProxyError, "Notification Proxy Error: #{err}" if err != :SUCCESS

    end

    def observe_notifications(notification_types)
	  ntypes_ary = []
	  notification_types.each do |ntype|
		ntypes_ary << FFI::MemoryPointer.from_string(ntype)
	  end
	  ntypes_ary << nil
	  ntypes = FFI::MemoryPointer.new(:pointer, ntypes_ary.length)
	  ntypes_ary.each_with_index do |p, i|
		ntypes[i].put_pointer(0, p)
	  end
	  err = C.np_observe_notifications(self, ntypes)
      raise NotificationProxyError, "Notification Proxy Error: #{err}" if err != :SUCCESS

    end

    def set_notify_callback(&block)
      err = C.np_set_notify_callback(self, _cb(&block), nil)
      raise NotificationProxyError, "Notification Proxy Error: #{err}" if err != :SUCCESS

      @notify_callback = block
      return true
    end

  private
    def _cb
      @_cb_procblk = Proc.new {|notification, junk| yield(notification) }
      return @_cb_procblk
    end
  end

  # Aliased short name for NotificationProxyClient
  NPClient = NotificationProxyClient

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS      ,         0,
      :INVALID_ARG  ,        -1,
      :PLIST_ERROR  ,        -2,
      :CONN_FAILED  ,        -3,
      :UNKNOWN_ERROR,      -256,
    ), :np_error_t

    #np_error_t np_client_new(idevice_t device, lockdownd_service_descriptor_t service, np_client_t *client);
    attach_function :np_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :np_error_t

    #np_error_t np_client_free(np_client_t client);
    attach_function :np_client_free, [NPClient], :np_error_t

    #np_error_t np_post_notification(np_client_t client, const char *notification);
    attach_function :np_post_notification, [NPClient, :string], :np_error_t

    #np_error_t np_observe_notification(np_client_t client, const char *notification);
    attach_function :np_observe_notification, [NPClient, :string], :np_error_t

    #np_error_t np_observe_notifications(np_client_t client, const char **notification_spec);
    attach_function :np_observe_notifications, [NPClient, :pointer], :np_error_t

    #/** Reports which notification was received. */
    #typedef void (*np_notify_cb_t) (const char *notification, void *user_data);
    callback :np_notify_cb_t, [:string, :pointer], :void

    #np_error_t np_set_notify_callback(np_client_t client, np_notify_cb_t notify_cb, void *userdata);
    attach_function :np_set_notify_callback, [NPClient, :np_notify_cb_t, :pointer], :np_error_t

  end
end
