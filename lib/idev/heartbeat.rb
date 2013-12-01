require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class HeartbeatError < IdeviceLibError
  end

  def self._handle_heartbeat_error(&block)
    err = block.call
    if err != :SUCCESS
      raise HeartbeatError, "Heartbeat error: #{err}"
    end
  end

  class HeartbeatClient < C::ManagedOpaquePointer
    def self.release(ptr)
      C.heartbeat_client_free(ptr) unless ptr.null?
    end

    # XXX TODO...
  end

  module C
    typedef enum(
      :SUCCESS      ,         0,
      :INVALID_ARG  ,        -1,
      :PLIST_ERROR  ,        -2,
      :MUX_ERROR    ,        -3,
      :SSL_ERROR    ,        -4,
      :UNKNOWN_ERROR,      -256,
    ), :heartbeat_error_t


    #heartbeat_error_t heartbeat_client_new(idevice_t device, lockdownd_service_descriptor_t service, heartbeat_client_t * client);
    attach_function :heartbeat_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :heartbeat_error_t

    #heartbeat_error_t heartbeat_client_start_service(idevice_t device, heartbeat_client_t * client, const char* label);
    attach_function :heartbeat_client_start_service, [Idevice, :pointer, :string], :heartbeat_error_t

    #heartbeat_error_t heartbeat_client_free(heartbeat_client_t client);
    attach_function :heartbeat_client_free, [HeartbeatClient], :heartbeat_error_t

    #heartbeat_error_t heartbeat_send(heartbeat_client_t client, plist_t plist);
    attach_function :heartbeat_send, [HeartbeatClient, Plist_t], :heartbeat_error_t

    #heartbeat_error_t heartbeat_receive(heartbeat_client_t client, plist_t * plist);
    attach_function :heartbeat_receive, [HeartbeatClient, :pointer], :heartbeat_error_t

    #heartbeat_error_t heartbeat_receive_with_timeout(heartbeat_client_t client, plist_t * plist, uint32_t timeout_ms);
    attach_function :heartbeat_receive_with_timeout, [HeartbeatClient, :pointer, :uint32], :heartbeat_error_t


  end
end
