require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class DiagnosticsRelayError < IdeviceLibError
  end

  def self._handle_drc_error(&block)
    err = block.call
    if err != :SUCCESS
      raise DiagnosticsRelayError, "Diagnostics Relay Error: #{err}"
    end
  end

  class DiagnosticsRelayClient < C::ManagedOpaquePointer
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
        Idev._handle_drc_error{ C.diagnostics_relay_client_new(idevice, ldsvc, p_drc) }
        drc = p_drc.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_client_new returned a NULL diagnostics_relay_client_t pointer" if drc.null?
        return new(drc)
      end
    end

    def diagnostics(type="All")
      FFI::MemoryPointer.new(:pointer) do |p_diags|
        Idev._handle_drc_error{ C.diagnostics_relay_request_diagnostics(self, type, p_diags) }
        diags = p_diags.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_request_diagnostics returned null diagnostics" if diags.null?
        return Plist_t.new(diags).to_ruby
      end
    end

    def mobilegestalt(*keys)
      FFI::MemoryPointer.new(:pointer) do |p_result|
        Idev._handle_drc_error{ C.diagnostics_relay_query_mobilegestalt(self, Plist_t.from_ruby(keys), p_result) }
        result = p_result.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_query_mobilegestalt returned a null result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def ioregistry_entry(name, klass)
      FFI::MemoryPointer.new(:pointer) do |p_result|
        Idev._handle_drc_error{ C.diagnostics_relay_query_ioregistry_entry(self, name, klass, p_result) }
        result = p_result.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_query_ioregistry_entry returned a null result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def ioregistry_plane(plane)
      FFI::MemoryPointer.new(:pointer) do |p_result|
        Idev._handle_drc_error{ C.diagnostics_relay_query_ioregistry_plane(self, plane, p_result) }
        result = p_result.read_pointer
        raise DiagnosticsRelayError, "diagnostics_relay_query_ioregistry_plane returned a null result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def goodbye
      Idev._handle_drc_error{ C.diagnostics_relay_goodbye(self) }
      return true
    end

    def sleep
      Idev._handle_drc_error{ C.diagnostics_relay_sleep(self) }
      return true
    end

    def restart(flags=0)
      Idev._handle_drc_error{ C.diagnostics_relay_restart(self, flags) }
      return true
    end

    def shutdown(flags=0)
      Idev._handle_drc_error{ C.diagnostics_relay_shutdown(self, flags) }
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