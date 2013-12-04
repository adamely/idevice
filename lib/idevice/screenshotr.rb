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
require 'idevice/idevice'
require 'idevice/lockdown'

module Idevice

  class ScreenShotrError < IdeviceLibError
  end

  class ScreenShotrClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C::Freelock.synchronize do
        unless ptr.null?
          C.screenshotr_client_free(ptr)
        end
      end
    end

    def self.attach(opts={})
      _attach_helper("com.apple.mobile.screenshotr", opts) do |idevice, ldsvc, p_ss|
        err = C.screenshotr_client_new(idevice, ldsvc, p_ss)
        raise ScreenShotrError, "ScreenShotr Error: #{err}" if err != :SUCCESS

        ss = p_ss.read_pointer
        raies ScreenShotrError, "screenshotr_client_new returned a NULL client" if ss.null?
        return new(ss)
      end
    end

    def take_screenshot
      FFI::MemoryPointer.new(:pointer) do |p_imgdata|
        FFI::MemoryPointer.new(:uint64) do |p_imgsize|
          err = C.screenshotr_take_screenshot(self, p_imgdata, p_imgsize)
          raise ScreenShotrError, "ScreenShotr Error: #{err}" if err != :SUCCESS

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

