require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class SbservicesError < IdeviceLibError
  end

  SBSError = SbservicesError

  def self._handle_sbs_error(err)
    if err != :SUCCESS
      raise SbservicesError, "Springboard Services Error: #{err}"
    end
  end

  class SbservicesClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.sbservices_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      _attach_helper("com.apple.springboardservices", opts) do |idevice, ldsvc, p_sbs|
        Idev._handle_sbs_error( C.sbservices_client_new(idevice, ldsvc, p_sbs) )
        sbs = p_sbs.read_pointer
        raise SBSError, "sbservices_client_new returned a NULL client" if sbs.null?
        return new(sbs)
      end
    end

    def get_icon_state
      FFI::MemoryPointer.new(:pointer) do |p_state|
        Idev._handle_sbs_error( C.sbservices_get_icon_state(self, p_state, nil))
        state = p_state.read_pointer
        if state
          return Plist_t.new(state).to_ruby
        end
      end
    end

    def set_icon_state(newstate)
      Idev._handle_sbs_error( C.sbservices_set_icon_state(self, newstate.to_plist_t) )
      return true
    end

    def get_icon_pngdata(bundleid)
      FFI::MemoryPointer.new(:pointer) do |p_pngdata|
        FFI::MemoryPointer.new(:uint64) do |p_pngsize|
          Idev._handle_sbs_error( C.sbservices_get_icon_pngdata(self, bundleid, p_pngdata, p_pngsize) )
          pngdata = p_pngdata.read_pointer
          unless pngdata.null?
            ret=pngdata.read_bytes(p_pngsize.read_uint64)
            C.free(pngdata)
            return ret
          end
        end
      end
    end

    INTERFACE_ORIENTATIONS = [
      :UNKNOWN,              # => 0,
      :PORTRAIT,             # => 1,
      :PORTRAIT_UPSIDE_DOWN, # => 2,
      :LANDSCAPE_RIGHT,      # => 3,
      :LANDSCAPE_LEFT,       # => 4,
    ]

    def get_interface_orientation
      FFI::MemoryPointer.new(:int) do |p_orientation|
        Idev._handle_sbs_error( C.sbservices_get_interface_orientation(self, p_orientation) )
        orientation = p_orientation.read_int
        return (INTERFACE_ORIENTATIONS[orientation] or orientation)
      end
    end

    #sbservices_error_t sbservices_get_home_screen_wallpaper_pngdata(sbservices_client_t client, char **pngdata, uint64_t *pngsize);
    #attach_function :sbservices_get_home_screen_wallpaper_pngdata, [SBSClient, :pointer, :pointer], :sbservices_error_t
    def get_home_screen_wallpaper_pngdata
      FFI::MemoryPointer.new(:pointer) do |p_pngdata|
        FFI::MemoryPointer.new(:uint64) do |p_pngsize|
          Idev._handle_sbs_error( C.sbservices_get_home_screen_wallpaper_pngdata(self, p_pngdata, p_pngsize) )
          pngdata = p_pngdata.read_pointer
          unless pngdata.null?
            ret=pngdata.read_bytes(p_pngsize.read_uint64)
            C.free(pngdata)
            return ret
          end
        end
      end
    end

  end

  SBSClient = SbservicesClient

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS      ,         0,
      :INVALID_ARG  ,        -1,
      :PLIST_ERROR  ,        -2,
      :CONN_FAILED  ,        -3,
      :UNKNOWN_ERROR,      -256,
    ), :sbservices_error_t

    #sbservices_error_t sbservices_client_new(idevice_t device, lockdownd_service_descriptor_t service, sbservices_client_t *client);
    attach_function :sbservices_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :sbservices_error_t

    #sbservices_error_t sbservices_client_free(sbservices_client_t client);
    attach_function :sbservices_client_free, [SBSClient], :sbservices_error_t

    #sbservices_error_t sbservices_get_icon_state(sbservices_client_t client, plist_t *state, const char *format_version);
    attach_function :sbservices_get_icon_state, [SBSClient, :pointer, :string], :sbservices_error_t

    #sbservices_error_t sbservices_set_icon_state(sbservices_client_t client, plist_t newstate);
    attach_function :sbservices_set_icon_state, [SBSClient, Plist_t], :sbservices_error_t

    #sbservices_error_t sbservices_get_icon_pngdata(sbservices_client_t client, const char *bundleId, char **pngdata, uint64_t *pngsize);
    attach_function :sbservices_get_icon_pngdata, [SBSClient, :string, :pointer, :pointer], :sbservices_error_t

    #sbservices_error_t sbservices_get_interface_orientation(sbservices_client_t client, sbservices_interface_orientation_t* interface_orientation);
    attach_function :sbservices_get_interface_orientation, [SBSClient, :pointer], :sbservices_error_t

    #sbservices_error_t sbservices_get_home_screen_wallpaper_pngdata(sbservices_client_t client, char **pngdata, uint64_t *pngsize);
    attach_function :sbservices_get_home_screen_wallpaper_pngdata, [SBSClient, :pointer, :pointer], :sbservices_error_t

  end
end
