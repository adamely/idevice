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
end

