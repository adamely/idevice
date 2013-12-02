require 'idev/c'
require 'idev/plist'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class MobileSyncError < IdeviceLibError
  end

  def self._handle_sync_error(&block)
    err = block.call
    if err != :SUCCESS
      raise MobileSyncError, "MobileSync error: #{err}"
    end
  end

  # Used to synchronize data classes with a device and computer.
  class MobileSyncClient < C::ManagedOpaquePointer
    include LibHelpers

    def self.release(ptr)
      C.mobilesync_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
        _attach_helper("com.apple.mobilesync", opts) do |idevice, ldsvc, p_ms|
        Idev._handle_sync_error{ C.mobilesync_client_new(idevice, ldsvc, p_ms) }
        ms = p_ms.read_pointer
        raise MobileSyncError, "mobilesync_client_new returned a NULL client" if ms.null?
        return new(ms)
      end
    end

    def receive_plist
      FFI::MemoryPointer.new(:pointer) do |p_result|
        Idev._handle_sync_error{ C.mobilesync_receive(self, p_result) }
        result = p_result.read_pointer
        raise MobileSyncError, "mobilesync_receive returned a null result" if result.null?
        return Plist_t.new(result).to_ruby
      end
    end

    def send_plist(request)
      Idev._handle_sync_error{ C.mobilesync_send(self, request.to_plist_t) }
      return true
    end

    #mobilesync_error_t mobilesync_start(mobilesync_client_t client, const char *data_class, mobilesync_anchors_t anchors, uint64_t computer_data_class_version, mobilesync_sync_type_t *sync_type, uint64_t *device_data_class_version, char** error_description);
    def start(data_class, anchors, computer_data_class_version)
      raise NotImplementedError # XXX TODO anchors arrays? RTFM
    end

    def cancel(reason)
      Idev._handle_sync_error{ C.mobilesync_cancel(self, reason) }
      return true
    end

    def finish
      Idev._handle_sync_error{ C.mobilesync_finish(self) }
      return true
    end

    def request_all_records_from_device
      Idev._handle_sync_error{ C.mobilesync_get_all_records_from_device(self) }
      return true
    end

    def request_changes_from_device
      Idev._handle_sync_error{ C.mobilesync_get_changes_from_device(self) }
      return true
    end

    def clear_all_records_on_device
      Idev._handle_sync_error{ C.mobilesync_clear_all_records_on_device(self) }
      return true
    end

    #mobilesync_error_t mobilesync_receive_changes(mobilesync_client_t client, plist_t *entities, uint8_t *is_last_record, plist_t *actions);
    def receive_changes
      raise NotImplementedError # XXX TODO RTFM
    end

    def acknowledge_changes_from_device
      Idev._handle_sync_error{ C.mobilesync_acknowledge_changes_from_device(self) }
      return true
    end

    def signal_ready_to_send_changes_from_computer
      Idev._handle_sync_error{ C.mobilesync_ready_to_send_changes_from_computer(self) }
      return true
    end

    #mobilesync_error_t mobilesync_send_changes(mobilesync_client_t client, plist_t entities, uint8_t is_last_record, plist_t actions);
    def send_changes(entities, actions=nil)
      raise NotImplementedError # XXX TODO RTFM
    end

    #mobilesync_error_t mobilesync_remap_identifiers(mobilesync_client_t client, plist_t *mapping);
    def remap_identifiers(mappings)
      raise NotImplementedError # XXX TODO RTFM
    end
  end

  # Mobile Sync anchors used by the device and computer
  class MobileSyncAnchors < FFI::ManagedStruct
    def self.release(ptr)
      C.mobilesync_anchors_free(ptr) unless ptr.null?
    end

    layout(
      :device_anchor,   :string,
      :computer_anchor, :string,
    )
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS        ,       0,
      :INVALID_ARG    ,      -1,
      :PLIST_ERROR    ,      -2,
      :MUX_ERROR      ,      -3,
      :BAD_VERSION    ,      -4,
      :SYNC_REFUSED   ,      -5,
      :CANCELLED      ,      -6,
      :WRONG_DIRECTION,      -7,
      :NOT_READY      ,      -8,
      :UNKNOWN_ERROR  ,    -256,
    ), :mobilesync_error_t

    ## The sync type of the current sync session.
    typedef enum(
      :FAST, # Fast-sync requires that only the changes made since the last synchronization should be reported by the computer.
      :SLOW, # Slow-sync requires that all data from the computer needs to be synchronized/sent.
      :RESET, # Reset-sync signals that the computer should send all data again.
    ), :mobilesync_sync_type_t

    #mobilesync_error_t mobilesync_client_new(idevice_t device, lockdownd_service_descriptor_t service, mobilesync_client_t * client);
    attach_function :mobilesync_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :mobilesync_error_t

    #mobilesync_error_t mobilesync_client_free(mobilesync_client_t client);
    attach_function :mobilesync_client_free, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_receive(mobilesync_client_t client, plist_t *plist);
    attach_function :mobilesync_receive, [MobileSyncClient, :pointer], :mobilesync_error_t

    #mobilesync_error_t mobilesync_send(mobilesync_client_t client, plist_t plist);
    attach_function :mobilesync_send, [MobileSyncClient, Plist_t], :mobilesync_error_t

    #mobilesync_error_t mobilesync_start(mobilesync_client_t client, const char *data_class, mobilesync_anchors_t anchors, uint64_t computer_data_class_version, mobilesync_sync_type_t *sync_type, uint64_t *device_data_class_version, char** error_description);
    attach_function :mobilesync_start, [MobileSyncClient, :string, MobileSyncAnchors, :uint64, :pointer, :pointer, :pointer], :mobilesync_error_t

    #mobilesync_error_t mobilesync_cancel(mobilesync_client_t client, const char* reason);
    attach_function :mobilesync_cancel, [MobileSyncClient, :string], :mobilesync_error_t

    #mobilesync_error_t mobilesync_finish(mobilesync_client_t client);
    attach_function :mobilesync_finish, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_get_all_records_from_device(mobilesync_client_t client);
    attach_function :mobilesync_get_all_records_from_device, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_get_changes_from_device(mobilesync_client_t client);
    attach_function :mobilesync_get_changes_from_device, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_clear_all_records_on_device(mobilesync_client_t client);
    attach_function :mobilesync_clear_all_records_on_device, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_receive_changes(mobilesync_client_t client, plist_t *entities, uint8_t *is_last_record, plist_t *actions);
    attach_function :mobilesync_receive_changes, [MobileSyncClient, :pointer, :pointer, :pointer], :mobilesync_error_t

    #mobilesync_error_t mobilesync_acknowledge_changes_from_device(mobilesync_client_t client);
    attach_function :mobilesync_acknowledge_changes_from_device, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_ready_to_send_changes_from_computer(mobilesync_client_t client);
    attach_function :mobilesync_ready_to_send_changes_from_computer, [MobileSyncClient], :mobilesync_error_t

    #mobilesync_error_t mobilesync_send_changes(mobilesync_client_t client, plist_t entities, uint8_t is_last_record, plist_t actions);
    attach_function :mobilesync_send_changes, [MobileSyncClient, Plist_t, :uint8, Plist_t], :mobilesync_error_t

    #mobilesync_error_t mobilesync_remap_identifiers(mobilesync_client_t client, plist_t *mapping);
    attach_function :mobilesync_remap_identifiers, [MobileSyncClient, :pointer], :mobilesync_error_t

    #mobilesync_anchors_t mobilesync_anchors_new(const char *device_anchor, const char *computer_anchor);
    attach_function :mobilesync_anchors_new, [:string, :string], MobileSyncAnchors

    #void mobilesync_anchors_free(mobilesync_anchors_t anchors);
    attach_function :mobilesync_anchors_free, [MobileSyncAnchors], :void


    ### actions Helpers

    #plist_t mobilesync_actions_new();
    attach_function :mobilesync_actions_new, [], Plist_t

    #void mobilesync_actions_add(plist_t actions, ...);
    attach_function :mobilesync_actions_add, [Plist_t, :varargs], Plist_t

    #void mobilesync_actions_free(plist_t actions);
    attach_function :mobilesync_actions_free, [Plist_t], :void

  end
end
