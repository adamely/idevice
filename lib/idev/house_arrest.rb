require 'idev/c'
require 'idev/idevice'
require 'idev/lockdown'
require 'idev/plist'

module Idev
  class HouseArrestClient < C::ManagedOpaquePointer
    def self.release(ptr)
      C.house_arrest_client_free(ptr) unless ptr.null?
    end
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS          ,     0,
      :INVALID_ARG      ,    -1,
      :PLIST_ERROR      ,    -2,
      :CONN_FAILED      ,    -3,
      :INVALID_MODE     ,    -4,

      :UNKNOWN_ERROR    ,  -256,
    ), :house_arrest_error_t

    #house_arrest_error_t house_arrest_client_new(idevice_t device, lockdownd_service_descriptor_t service, house_arrest_client_t *client);
    attach_function :house_arrest_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :house_arrest_error_t

    #house_arrest_error_t house_arrest_client_free(house_arrest_client_t client);
    attach_function :house_arrest_client_free, [HouseArrestClient], :house_arrest_error_t

    #house_arrest_error_t house_arrest_send_request(house_arrest_client_t client, plist_t dict);
    attach_function :house_arrest_send_request, [HouseArrestClient, Plist_t], :house_arrest_error_t

    #house_arrest_error_t house_arrest_send_command(house_arrest_client_t client, const char *command, const char *appid);
    attach_function :house_arrest_send_command, [HouseArrestClient, :string, :string], :house_arrest_error_t

    #house_arrest_error_t house_arrest_get_result(house_arrest_client_t client, plist_t *dict);
    attach_function :house_arrest_get_result, [HouseArrestClient, :pointer], :house_arrest_error_t

  end
end
