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
require 'idevice/plist'
require 'idevice/idevice'
require 'idevice/lockdown'

module Idevice
  class WebInspectorError < IdeviceLibError
  end

  class WebInspectorClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.webinspector_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      _attach_helper("com.apple.webinspector", opts) do |idevice, ldsvc, p_wic|
        err = C.webinspector_client_new(idevice, ldsvc, p_wic)
        raise WebInspectorError, "WebInspector error: #{err}" if err != :SUCCESS

        wic = p_wic.read_pointer
        raise WebInspectorError, "webinspector_client_new returned a NULL client" if wic.null?

        return new(wic)
      end
    end

    def send_plist(obj)
      err = C.webinspector_send(self, Plist_t.from_ruby(obj))
      raise WebInspectorError, "WebInspector error: #{err}" if err != :SUCCESS
      return true
    end

    def receive_plist
      FFI::MemoryPointer.new(:pointer) do |p_plist|
        err = C.webinspector_receive(self, p_plist)
        raise WebInspectorError, "WebInspector error: #{err}" if err != :SUCCESS
        return p_plist.to_pointer.to_plist_t
      end
    end
  end

  module C

    typedef enum(
      :SUCCESS      ,         0,
      :INVALID_ARG  ,        -1,
      :PLIST_ERROR  ,        -2,
      :MUX_ERROR    ,        -3,
      :SSL_ERROR    ,        -4,
      :UNKNOWN_ERROR,      -256,
    ), :webinspector_error_t

    #webinspector_error_t webinspector_client_new(idevice_t device, lockdownd_service_descriptor_t service, webinspector_client_t * client);
    attach_function :webinspector_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :webinspector_error_t

    #webinspector_error_t webinspector_client_start_service(idevice_t device, webinspector_client_t * client, const char* label);
    attach_function :webinspector_client_start_service, [Idevice, :pointer, :string], :webinspector_error_t

    #webinspector_error_t webinspector_client_free(webinspector_client_t client);
    attach_function :webinspector_client_free, [WebInspectorClient], :webinspector_error_t

    #webinspector_error_t webinspector_send(webinspector_client_t client, plist_t plist);
    attach_function :webinspector_send, [WebInspectorClient, Plist_t], :webinspector_error_t

    #webinspector_error_t webinspector_receive(webinspector_client_t client, plist_t * plist);
    attach_function :webinspector_receive, [WebInspectorClient, :pointer], :webinspector_error_t

    #webinspector_error_t webinspector_receive_with_timeout(webinspector_client_t client, plist_t * plist, uint32_t timeout_ms);
    attach_function :webinspector_receive_with_timeout, [WebInspectorClient, :pointer, :uint32], :webinspector_error_t

  end
end


