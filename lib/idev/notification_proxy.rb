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

  class NotificationProxyClient < C::ManagedOpaquePointer
    def self.release(ptr)
      C.np_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      idevice = opts[:idevice] || Idevice.attach(opts)
      ldsvc = opts[:lockdown_service]
      unless ldsvc
        ldclient = opts[:lockdown_client] || LockdownClient.attach(opts.merge(idevice:idevice))
        ldsvc = ldclient.start_service("com.apple.mobile.notification_proxy")
      end

      FFI::MemoryPointer.new(:pointer) do |p_np|
        Idev._handle_np_error{ C.np_client_new(idevice, ldsvc, p_np) }
        np = p_np.read_pointer
        raise NPError, "np_client_new returned a NULL client" if np.null?
        return new(np)
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
