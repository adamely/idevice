require 'rubygems'

require 'idev/version'
require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'
require 'idev/house_arrest'
require 'idev/afc'
require 'idev/installation_proxy'
require 'idev/misagent'
require 'idev/diagnostics_relay'
require 'idev/file_relay'

module Idev
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
          raise Idev::IdeviceError, "Library error: #{ierr}"
        end
      end
    end
  end
end

