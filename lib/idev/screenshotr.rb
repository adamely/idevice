require 'idev/c'
require 'idev/idevice'
require 'idev/lockdown'

module Idev

  class ScreenShotrError < IdeviceLibError
  end

  def self._handle_sshot_error(err)
    if err != :SUCCESS
      raise ScreenShotrError, "ScreenShotr Error: #{err}"
    end
  end

  class ScreenShotrClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.screenshotr_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      _attach_helper("com.apple.mobile.screenshotr", opts) do |idevice, ldsvc, p_ss|
        Idev._handle_sshot_error( C.screenshotr_client_new(idevice, ldsvc, p_ss) )
        ss = p_ss.read_pointer
        raies ScreenShotrError, "screenshotr_client_new returned a NULL client" if ss.null?
        return new(ss)
      end
    end

    def take_screenshot
      FFI::MemoryPointer.new(:pointer) do |p_imgdata|
        FFI::MemoryPointer.new(:uint64) do |p_imgsize|
          Idev._handle_sshot_error( C.screenshotr_take_screenshot(self, p_imgdata, p_imgsize) )
          imgdata = p_imgdata.read_pointer
          unless imgdata.null?
            ret=imgdata.read_bytes(p_imgsize.read_uint64)
            C.free(imgdata)
            return ret
          end
        end
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
      :BAD_VERSION  ,        -4,
      :UNKNOWN_ERROR,      -256,
    ), :screenshotr_error_t

    #screenshotr_error_t screenshotr_client_new(idevice_t device, lockdownd_service_descriptor_t service, screenshotr_client_t * client);
    attach_function :screenshotr_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :screenshotr_error_t

    #screenshotr_error_t screenshotr_client_free(screenshotr_client_t client);
    attach_function :screenshotr_client_free, [ScreenShotrClient], :screenshotr_error_t

    #screenshotr_error_t screenshotr_take_screenshot(screenshotr_client_t client, char **imgdata, uint64_t *imgsize);
    attach_function :screenshotr_take_screenshot, [ScreenShotrClient, :pointer, :pointer], :screenshotr_error_t

  end
end

