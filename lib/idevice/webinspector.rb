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
  class WebInspectorError < IdeviceLibError
  end

  class WebInspectorClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C::Freelock.synchronize do
        unless ptr.null?
          C.webinspector_client_free(ptr)
        end
      end
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


