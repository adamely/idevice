require 'idev/c'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class NotificationProxyError < IdeviceLibError
  end

  # Aliased short name for NotificationProxyError
  NPError = NotificationProxyError

  def self._handle_np_error(&block)
    err=block.call
    if err != :SUCCESS
      raise NotificationProxyError, "Notification Proxy Error: #{err}"
    end
  end

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

  class NotificationProxyClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.np_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      _attach_helper("com.apple.mobile.notification_proxy", opts) do |idevice, ldsvc, p_np|
        Idev._handle_np_error{ C.np_client_new(idevice, ldsvc, p_np) }
        np = p_np.read_pointer
        raise NPError, "np_client_new returned a NULL client" if np.null?
        return new(np)
      end
    end

    def post_notification(notification)
      Idev._handle_np_error{ C.np_post_notification(self, notification) }
      return true
    end

    def observe_notification
      FFI::MemoryPointer.new(:pointer) do |p_notification|
        Idev._handle_np_error{ C.np_observe_notification(self, p_notification) }
        notification = p_notification.read_pointer
        unless notification.null?
          ret = notification.read_string
          C.free(notification)
          return ret
        end
      end
    end

    def observe_notifications
      FFI::MemoryPointer.new(:pointer) do |p_notifications|
        Idev._handle_np_error{ C.np_observe_notifications(self, p_notifications) }
        return _unbound_list_to_array(p_notifications)
      end
    end

    def set_notify_callback(&block)
      Idev._handle_np_error{ C.np_set_notify_callback(self, _cb(&block), nil) }
      @notify_callback = block
      return true
    end

  private
    def _cb
      lambda do |notification, junk|
        yield(notification)
      end
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
