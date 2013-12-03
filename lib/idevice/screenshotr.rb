#
# Copyright (c) 2013 Eric Monti
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'idevice/c'
require 'idevice/idevice'
require 'idevice/lockdown'

module Idevice

  class ScreenShotrError < IdeviceLibError
  end

  class ScreenShotrClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.screenshotr_client_free(ptr) unless ptr.null?
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

