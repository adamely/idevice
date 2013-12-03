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

