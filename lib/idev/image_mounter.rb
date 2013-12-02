require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'


module Idev
  class ImageMounterError < IdeviceLibError
  end

  def self._handle_mim_error(&block)
    err = block.call
    if err != :SUCCESS
      raise ImageMounterError, "ImageMounter error: #{err}"
    end
  end

  # Used to mount developer/debug disk images on the device.
  class ImageMounterClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.mobile_image_mounter_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      _attach_helper("com.apple.mobile.mobile_image_mounter", opts) do |idevice, ldsvc, p_mim|
        Idev._handle_mim_error{ C.mobile_image_mounter_new(idevice, ldsvc, p_mim) }
        mim = p_mim.read_pointer
        raise ImageMounterError, "mobile_image_mounter_new returned a NULL client" if mim.null?
        return new(mim)
      end
    end

    def lookup_image(image_type="Developer")
      FFI::MemoryPointer.new(:pointer) do |p_result|
        Idev._handle_mim_error{ C.mobile_image_mounter_lookup_image(self, image_type, p_result) }
        result = p_result.read_pointer
        raise ImageMounterError, "mobile_image_mounter_lookup_image returned a NULL result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def mount_image(path, signature, image_type="Developer")
      FFI::MemoryPointer.from_bytes(signature) do |p_signature|
        FFI::MemoryPointer.new(:pointer) do |p_result|
          Idev._handle_mim_error{ C.mobile_image_mounter_mount_image(self, path, p_signature, p_signature.size, image_type, p_result) }
          result = p_result.read_pointer
          raise ImageMounterError, "mobile_image_mounter_mount_image returned a NULL result" if result.null?
          return Plist_t.new(result).to_ruby
        end
      end
    end

    def hangup
      Idev._handle_mim_error{ C.mobile_image_mounter_hangup(self) }
      return true
    end
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS      ,          0,
      :INVALID_ARG  ,         -1,
      :PLIST_ERROR  ,         -2,
      :CONN_FAILED  ,         -3,
      :UNKNOWN_ERROR,       -256,
    ), :image_mounter_error_t

    #mobile_image_mounter_error_t mobile_image_mounter_new(idevice_t device, lockdownd_service_descriptor_t service, mobile_image_mounter_client_t *client);
    attach_function :mobile_image_mounter_new, [Idevice, LockdownServiceDescriptor, :pointer], :image_mounter_error_t

    #mobile_image_mounter_error_t mobile_image_mounter_free(mobile_image_mounter_client_t client);
    attach_function :mobile_image_mounter_free, [ImageMounterClient], :image_mounter_error_t

    #mobile_image_mounter_error_t mobile_image_mounter_lookup_image(mobile_image_mounter_client_t client, const char *image_type, plist_t *result);
    attach_function :mobile_image_mounter_lookup_image, [ImageMounterClient, :string, :pointer], :image_mounter_error_t

    #mobile_image_mounter_error_t mobile_image_mounter_mount_image(mobile_image_mounter_client_t client, const char *image_path, const char *image_signature, uint16_t signature_length, const char *image_type, plist_t *result);
    attach_function :mobile_image_mounter_mount_image, [ImageMounterClient, :string, :pointer, :uint16, :string, :pointer], :image_mounter_error_t

    #mobile_image_mounter_error_t mobile_image_mounter_hangup(mobile_image_mounter_client_t client);
    attach_function :mobile_image_mounter_hangup, [ImageMounterClient], :image_mounter_error_t

  end
end
