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

require 'rubygems'

require 'idevice/version'
require 'idevice/c'
require 'idevice/plist'
require 'idevice/idevice'
require 'idevice/lockdown'
require 'idevice/house_arrest'
require 'idevice/afc'
require 'idevice/installation_proxy'
require 'idevice/misagent'
require 'idevice/diagnostics_relay'
require 'idevice/file_relay'
require 'idevice/heartbeat'
require 'idevice/image_mounter'
require 'idevice/mobilebackup'
require 'idevice/mobilebackup2'
require 'idevice/mobilesync'
require 'idevice/notification_proxy'
require 'idevice/restore'
require 'idevice/sbservices'
require 'idevice/screenshotr'
require 'idevice/webinspector'

module Idevice
  def self.debug_level= num
    C.idevice_set_debug_level(num)
  end

  def self.device_list
    FFI::MemoryPointer.new(:int) do |countp|
      FFI::MemoryPointer.new(:pointer) do |devices|
        ierr = C.idevice_get_device_list(devices, countp)
        if ierr == :SUCCESS
          ret = []
          count = countp.read_int
          if count > 0
            devices.read_pointer.read_array_of_pointer(count).map { |sp| ret << sp.read_string }
          end
          C.idevice_device_list_free(devices.read_pointer)
          return ret
        else
          raise Idevice::IdeviceError, "Library error: #{ierr}"
        end
      end
    end
  end

  # listens for event connection and disconnection events
  def self.subscribe
    finished = false

    cb = Proc.new do |eventp, junk|
      unless eventp.nil? or eventp.null?
        evt = C::DEVICE_EVENTS[eventp.read_int] || :UNKNOWN
        finished = yield(evt)
      end
    end

    begin
      C.idevice_event_subscribe(cb, nil)
      until finished
        #nop
      end
    ensure
      C.idevice_event_unsubscribe()
    end
    nil
  end

  def self.wait_for_device_add(opts={})
    udid = opts[:udid]
    if udid
      return if device_list.include?(udid)
    end

    subscribe do |evt|
      if evt == :DEVICE_ADD
        if udid 
          self.device_list.include?(udid)
        else
          true
        end
      else
        false
      end
    end
  end

  def self.wait_for_device_remove(opts={})
    udid = opts[:udid]
    if udid
      return unless device_list.include?(udid)
    end

    subscribe do |evt|
      if evt == :DEVICE_REMOVE
        if udid
          (not self.device_list.include?(udid))
        else
          true
        end
      else
        false
      end
    end
  end
end

