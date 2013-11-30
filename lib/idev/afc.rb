require 'idev/c'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class Idev::AFC < C::ManagedOpaquePointer
    def self.release(ptr)
      C.afc_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
    end
  end

  module C
    ffi_lib 'imobiledevice'

    typedef enum(
      :SUCCESS              ,   0,
      :UNKNOWN_ERROR        ,   1,
      :OP_HEADER_INVALID    ,   2,
      :NO_RESOURCES         ,   3,
      :READ_ERROR           ,   4,
      :WRITE_ERROR          ,   5,
      :UNKNOWN_PACKET_TYPE  ,   6,
      :INVALID_ARG          ,   7,
      :OBJECT_NOT_FOUND     ,   8,
      :OBJECT_IS_DIR        ,   9,
      :PERM_DENIED          ,  10,
      :SERVICE_NOT_CONNECTED,  11,
      :OP_TIMEOUT           ,  12,
      :TOO_MUCH_DATA        ,  13,
      :END_OF_DATA          ,  14,
      :OP_NOT_SUPPORTED     ,  15,
      :OBJECT_EXISTS        ,  16,
      :OBJECT_BUSY          ,  17,
      :NO_SPACE_LEFT        ,  18,
      :OP_WOULD_BLOCK       ,  19,
      :IO_ERROR             ,  20,
      :OP_INTERRUPTED       ,  21,
      :OP_IN_PROGRESS       ,  22,
      :INTERNAL_ERROR       ,  23,

      :MUX_ERROR            ,  30,
      :NO_MEM               ,  31,
      :NOT_ENOUGH_DATA      ,  32,
      :DIR_NOT_EMPTY        ,  33,
    ), :afc_error_t

    typedef enum(
      :RDONLY   , 0x00000001, # r   O_RDONLY
      :RW       , 0x00000002, # r+  O_RDWR   | O_CREAT
      :WRONLY   , 0x00000003, # w   O_WRONLY | O_CREAT  | O_TRUNC
      :WR       , 0x00000004, # w+  O_RDWR   | O_CREAT  | O_TRUNC
      :APPEND   , 0x00000005, # a   O_WRONLY | O_APPEND | O_CREAT
      :RDAPPEND , 0x00000006,  # a+  O_RDWR   | O_APPEND | O_CREAT
    ), :afc_file_mode_t

    typedef enum(
      :HARDLINK , 1,
      :SYMLINK , 2,
    ), :afc_link_type_t

    typedef enum(
      :SHARED,      (1 | 4),
      :EXCLUSIVE,   (2 | 4),
      :UNLOCK,      (8 | 4),
    ), :afc_lock_op_t;

    typedef enum( :SEEK_SET, :SEEK_CUR, :SEEK_END ), :whence_t

    typedef :pointer, :afc_client_t

    # afc_error_t afc_client_new(idevice_t device, lockdownd_service_descriptor_t service, afc_client_t *client);
    attach_function :afc_client_new, [Idevice, LockdowndServiceDescriptor, :pointer], :afc_error_t

    # afc_error_t afc_client_free(afc_client_t client);
    attach_function :afc_client_free, [:afc_client_t], :afc_error_t

    # afc_error_t afc_get_device_info(afc_client_t client, char ***infos);
    attach_function :afc_get_device_info, [:afc_client_t, :pointer], :afc_error_t

    # afc_error_t afc_read_directory(afc_client_t client, const char *dir, char ***list);
    attach_function :afc_read_directory, [:afc_client_t, :string, :pointer], :afc_error_t

    # afc_error_t afc_get_file_info(afc_client_t client, const char *filename, char ***infolist);
    attach_function :afc_get_file_info, [:afc_client_t, :string, :pointer], :afc_error_t

    # afc_error_t afc_file_open(afc_client_t client, const char *filename, afc_file_mode_t file_mode, uint64_t *handle);
    attach_function :afc_file_open, [:afc_client_t, :string, :afc_file_mode_t, :pointer], :afc_error_t

    # afc_error_t afc_file_close(afc_client_t client, uint64_t handle);
    attach_function :afc_file_close, [:afc_client_t, :uint64], :afc_error_t

    # afc_error_t afc_file_lock(afc_client_t client, uint64_t handle, afc_lock_op_t operation);
    attach_function :afc_file_lock, [:afc_client_t, :uint64, :afc_lock_op_t], :afc_error_t

    # afc_error_t afc_file_read(afc_client_t client, uint64_t handle, char *data, uint32_t length, uint32_t *bytes_read);
    attach_function :afc_file_read, [:afc_client_t, :uint64, :pointer, :uint32, :pointer], :afc_error_t

    # afc_error_t afc_file_write(afc_client_t client, uint64_t handle, const char *data, uint32_t length, uint32_t *bytes_written);
    attach_function :afc_file_write, [:afc_client_t, :uint64, :string, :uint32, :pointer], :afc_error_t

    # afc_error_t afc_file_seek(afc_client_t client, uint64_t handle, int64_t offset, int whence);
    attach_function :afc_file_seek, [:afc_client_t, :uint64, :int64, :whence_t], :afc_error_t

    # afc_error_t afc_file_tell(afc_client_t client, uint64_t handle, uint64_t *position);
    attach_function :afc_file_tell, [:afc_client_t, :uint64, :pointer], :afc_error_t

    # afc_error_t afc_file_truncate(afc_client_t client, uint64_t handle, uint64_t newsize);
    attach_function :afc_file_truncate, [:afc_client_t, :uint64, :uint64], :afc_error_t

    # afc_error_t afc_remove_path(afc_client_t client, const char *path);
    attach_function :afc_remove_path, [:afc_client_t, :string], :afc_error_t

    # afc_error_t afc_rename_path(afc_client_t client, const char *from, const char *to);
    attach_function :afc_rename_path, [:afc_client_t, :string, :string], :afc_error_t

    # afc_error_t afc_make_directory(afc_client_t client, const char *dir);
    attach_function :afc_make_directory, [:afc_client_t, :string], :afc_error_t

    # afc_error_t afc_truncate(afc_client_t client, const char *path, uint64_t newsize);
    attach_function :afc_truncate, [:afc_client_t, :string, :uint64], :afc_error_t

    # afc_error_t afc_make_link(afc_client_t client, afc_link_type_t linktype, const char *target, const char *linkname);
    attach_function :afc_make_link, [:afc_client_t, :afc_link_type_t, :string, :string], :afc_error_t

    # afc_error_t afc_set_file_time(afc_client_t client, const char *path, uint64_t mtime);
    attach_function :afc_set_file_time, [:afc_client_t, :string, :uint64], :afc_error_t

    # afc_error_t afc_get_device_info_key(afc_client_t client, const char *key, char **value);
    attach_function :afc_get_device_info_key, [:afc_client_t, :string, :pointer], :afc_error_t

  end
end
