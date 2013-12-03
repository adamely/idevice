require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class DiagnosticsRelayError < IdeviceLibError
  end

  class DiagnosticsRelayClient < C::ManagedOpaquePointer
    include LibHelpers

    FLAG_WAIT_FOR_DISCONNECT = (1 << 1)
    FLAG_DISPLAY_PASS        = (1 << 2)
    FLAG_DISPLAY_FAIL        = (1 << 3)

    REQUEST_TYPES = [
      "All",
      "HDMI",
      "WiFi",
      "GasGaugue",
      "NAND",
    ]

    def self.release(ptr)
      C.diagnostics_relay_client_free(ptr) unless ptr.null?
    end


    def self.attach(opts={})
      # Note, we're not using LibHelpers#_attach_helper since we need to do the fallback to
      # the old relay service name below

      idevice = opts[:idevice] || Idevice.attach(opts)
      ldsvc = opts[:lockdown_service]
      unless ldsvc
        ldclient = opts[:lockdown_client] || LockdownClient.attach(opts.merge(idevice:idevice))
        ldsvc = begin
                  ldclient.start_service("com.apple.mobile.diagnostics_relay")
                rescue LockdownError
                  # fall-back to old diagnostics relay service name
                  ldclient.start_service("com.apple.iosdiagnostics.relay")
                end
      end

      FFI::MemoryPointer.new(:pointer) do |p_drc|
        err = C.diagnostics_relay_client_new(idevice, ldsvc, p_drc)
        raise DiagnosticsRelayError, "Diagnostics Relay error: #{err}" if err != :SUCCESS
        drc = p_drc.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_client_new returned a NULL diagnostics_relay_client_t pointer" if drc.null?
        return new(drc)
      end
    end

    def diagnostics(type="All")
      FFI::MemoryPointer.new(:pointer) do |p_diags|
        err = C.diagnostics_relay_request_diagnostics(self, type, p_diags)
        raise DiagnosticsRelayError, "Diagnostics Relay error: #{err}" if err != :SUCCESS

        diags = p_diags.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_request_diagnostics returned null diagnostics" if diags.null?
        return Plist_t.new(diags).to_ruby
      end
    end

    def mobilegestalt(*keys)
      FFI::MemoryPointer.new(:pointer) do |p_result|
        err = C.diagnostics_relay_query_mobilegestalt(self, Plist_t.from_ruby(keys), p_result)
        raise DiagnosticsRelayError, "Diagnostics Relay error: #{err}" if err != :SUCCESS
        result = p_result.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_query_mobilegestalt returned a null result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def ioregistry_entry(name, klass)
      FFI::MemoryPointer.new(:pointer) do |p_result|
        err = C.diagnostics_relay_query_ioregistry_entry(self, name, klass, p_result)
        raise DiagnosticsRelayError, "Diagnostics Relay error: #{err}" if err != :SUCCESS
        result = p_result.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_query_ioregistry_entry returned a null result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def ioregistry_plane(plane)
      FFI::MemoryPointer.new(:pointer) do |p_result|
        err = C.diagnostics_relay_query_ioregistry_plane(self, plane, p_result)
        raise DiagnosticsRelayError, "Diagnostics Relay error: #{err}" if err != :SUCCESS
        result = p_result.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_query_ioregistry_plane returned a null result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def goodbye
      err = C.diagnostics_relay_goodbye(self)
      raise DiagnosticsRelayError, "Diagnostics Relay error: #{err}" if err != :SUCCESS
      return true
    end

    def sleep
      err = C.diagnostics_relay_sleep(self)
      raise DiagnosticsRelayError, "Diagnostics Relay error: #{err}" if err != :SUCCESS
      return true
    end

    def restart(flags=0)
      err = C.diagnostics_relay_restart(self, flags)
      raise DiagnosticsRelayError, "Diagnostics Relay error: #{err}" if err != :SUCCESS
      return true
    end

    def shutdown(flags=0)
      err = C.diagnostics_relay_shutdown(self, flags)
      raise DiagnosticsRelayError, "Diagnostics Relay error: #{err}" if err != :SUCCESS
      return true
    end
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS         ,     0,
      :INVALID_ARG     ,    -1,
      :PLIST_ERROR     ,    -2,
      :MUX_ERROR       ,    -3,
      :UNKNOWN_REQUEST ,    -4,
      :UNKNOWN_ERROR   ,  -256,
    ), :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_client_new(idevice_t device, lockdownd_service_descriptor_t service, diagnostics_relay_client_t *client);
    attach_function :diagnostics_relay_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_client_free(diagnostics_relay_client_t client);
    attach_function :diagnostics_relay_client_free, [DiagnosticsRelayClient], :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_goodbye(diagnostics_relay_client_t client);
    attach_function :diagnostics_relay_goodbye, [DiagnosticsRelayClient], :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_sleep(diagnostics_relay_client_t client);
    attach_function :diagnostics_relay_sleep, [DiagnosticsRelayClient], :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_restart(diagnostics_relay_client_t client, int flags);
    attach_function :diagnostics_relay_restart, [DiagnosticsRelayClient, :int], :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_shutdown(diagnostics_relay_client_t client, int flags);
    attach_function :diagnostics_relay_shutdown, [DiagnosticsRelayClient, :int], :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_request_diagnostics(diagnostics_relay_client_t client, const char* type, plist_t* diagnostics);
    attach_function :diagnostics_relay_request_diagnostics, [DiagnosticsRelayClient, :string, :pointer], :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_query_mobilegestalt(diagnostics_relay_client_t client, plist_t keys, plist_t* result);
    attach_function :diagnostics_relay_query_mobilegestalt, [DiagnosticsRelayClient, Plist_t, :pointer], :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_query_ioregistry_entry(diagnostics_relay_client_t client, const char* name, const char* class, plist_t* result);
    attach_function :diagnostics_relay_query_ioregistry_entry, [DiagnosticsRelayClient, :string, :string, :pointer], :diagnostics_relay_error_t

    #diagnostics_relay_error_t diagnostics_relay_query_ioregistry_plane(diagnostics_relay_client_t client, const char* plane, plist_t* result);
    attach_function :diagnostics_relay_query_ioregistry_plane, [DiagnosticsRelayClient, :string, :pointer], :diagnostics_relay_error_t


  end
end
