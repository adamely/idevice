require 'idevice/c'
require 'idevice/plist'
require 'idevice/idevice'
require 'idevice/lockdown'

module Idevice
  class HeartbeatError < IdeviceLibError
  end

  class HeartbeatClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.heartbeat_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      _attach_helper("com.apple.mobile.heartbeat", opts) do |idevice, ldsvc, p_hb|
        err=C.heartbeat_client_new(idevice, ldsvc, p_hb)
        raise HeartbeatError, "Heartbeat error: #{err}" if err != :SUCCESS
        hb = p_hb.read_pointer
        raise HeartbeatError, "hearbeat_client_new returned a NULL client" if hb.null?
        return new(hb)
      end
    end

    def send_plist(obj)
      err = C.heartbeat_send(self, obj.to_plist_t)
      raise HeartbeatError, "Heartbeat error: #{err}" if err != :SUCCESS
      return true
    end

    def receive_plist(timeout=nil)
      timeout ||= 1

      FFI::MemoryPointer.new(:pointer) do |p_plist|
        err = C.heartbeat_receive_with_timeout(self, p_plist, timeout)
        raise HeartbeatError, "Heartbeat error: #{err}" if err != :SUCCESS
        plist = p_plist.read_pointer
        raise HeartbeatError, "hearbeat_receive returned a NULL plist" if plist.null?
        return Plist.new(plist).to_ruby
      end
    end

  end

  module C
    ffi_lib 'imobiledevice'

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
