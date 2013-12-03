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
require 'idevice/plist'
require 'idevice/idevice'
require 'idevice/lockdown'


module Idevice
  class ImageMounterError < IdeviceLibError
  end

  # Used to mount developer/debug disk images on the device.
  class ImageMounterClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.mobile_image_mounter_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      _attach_helper("com.apple.mobile.mobile_image_mounter", opts) do |idevice, ldsvc, p_mim|
        err = C.mobile_image_mounter_new(idevice, ldsvc, p_mim)
        raise ImageMounterError, "ImageMounter error: #{err}" if err != :SUCCESS

        mim = p_mim.read_pointer
        raise ImageMounterError, "mobile_image_mounter_new returned a NULL client" if mim.null?
        return new(mim)
      end
    end

    def is_mounted?(image_type="Developer")
      ret = lookup_image(image_type)
      return (ret["ImagePresent"] == true)
    end

    def lookup_image(image_type="Developer")
      FFI::MemoryPointer.new(:pointer) do |p_result|
        err = C.mobile_image_mounter_lookup_image(self, image_type, p_result)
        raise ImageMounterError, "ImageMounter error: #{err}" if err != :SUCCESS

        result = p_result.read_pointer.read_plist_t
        raise ImageMounterError, "mobile_image_mounter_lookup_image returned a NULL result" if result.nil?

        return result
      end
    end

    def mount_image(path, signature, image_type="Developer")
      signature = signature.dup.force_encoding('binary')
      FFI::MemoryPointer.from_bytes(signature) do |p_signature|
        FFI::MemoryPointer.new(:pointer) do |p_result|
          err = C.mobile_image_mounter_mount_image(self, path, p_signature, p_signature.size, image_type, p_result)
          raise ImageMounterError, "ImageMounter error: #{err}" if err != :SUCCESS

          result = p_result.read_pointer.read_plist_t
          raise ImageMounterError, "mobile_image_mounter_mount_image returned a NULL result" if result.nil?

          return result
        end
      end
    end

    def hangup
      err = C.mobile_image_mounter_hangup(self)
      raise ImageMounterError, "ImageMounter error: #{err}" if err != :SUCCESS

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
