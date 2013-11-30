
require "rubygems"
require 'plist'
require "ffi"

module FFI
  class MemoryPointer < Pointer
    def self.from_bytes(data)
      if block_given?
        new(data.size) do |p|
          p.write_bytes(data)
          yield(p)
        end
      else
        p = new(data.size)
        p.write_bytes(data)
        p
      end
    end
  end
end

module Idev
  module C
    extend FFI::Library

    class ManagedPointer < FFI::AutoPointer
      def initialize(ptr)
        raise NoMethodError, "release() not implemented for class #{self}" unless self.class.respond_to? :release
        super(ptr, self.class.method(:release))
      end
    end

    #----------------------------------------------------------------------
    ffi_lib FFI::Library::LIBC

    # memory allocators
    attach_function :malloc, [:size_t], :pointer
    attach_function :calloc, [:size_t], :pointer
    attach_function :valloc, [:size_t], :pointer
    attach_function :realloc, [:pointer, :size_t], :pointer
    attach_function :free, [:pointer], :void

    # memory movers
    attach_function :memcpy, [:pointer, :pointer, :size_t], :pointer
    attach_function :bcopy, [:pointer, :pointer, :size_t], :void


    #----------------------------------------------------------------------
    ffi_lib 'plist'

    class Plist_t < ManagedPointer
      def self.release(ptr)
        ::Idev::C.plist_free(ptr) unless ptr.null?
      end

      def self.new_array
        C.plist_new_array()
      end

      def self.new_dict
        C.plist_new_dict()
      end

      def self.from_xml(xml)
        FFI::MemoryPointer.from_bytes(xml) do |plist_xml|
          FFI::MemoryPointer.new(:pointer) do |p_out|
            C.plist_from_xml(plist_xml, plist_xml.size, p_out)
            out = p_out.read_pointer
            if out.null?
              return nil
            else
              return new(out)
            end
          end
        end
      end

      def self.from_binary(data)
        FFI::MemoryPointer.from_bytes(data) do |plist_bin|
          FFI::MemoryPointer.new(:pointer) do |p_out|
            C.plist_from_bin(plist_bin, plist_bin.size, p_out)
            out = p_out.read_pointer
            if out.null?
              return nil
            else
              return new(out)
            end
          end
        end
      end

      def self.new_bool(val)
        C.plist_new_bool(val)
      end

      def self.new_string(str)
        C.plist_new_string(str)
      end

      def self.new_real(val)
        C.plist_new_real(val)
      end

      def self.new_uint(val)
        C.plist_new_uint(val)
      end

      def self.new_uid(val)
        C.plist_new_uint(val)
      end

      def self.new_data(data)
        FFI::MemoryPointer.from_bytes(data) do |p_data|
          FFI::MemoryPointer.new(:pointer) do |p_out|
            return C.plist_new_data(p_data, p_data.size)
          end
        end
      end

      def self.from_ruby(obj)
        case obj
          when TrueClass,FalseClass
            new_bool(obj)
          when Hash, Array
            from_xml(obj.to_plist)
          when String
            new_string(obj)
          when StringIO
            new_data(obj.string)
          when Float
            new_real(obj)
          when Integer
            new_uint(obj)
          when Time,DateTime
            raise NotImplementedError # XXX TODO
          else
            raise TypeError, "Unable to convert #{obj.class} to a plist"
        end
      end

      def to_ruby
        FFI::MemoryPointer.new(:pointer) do |plist_xml_p|
          FFI::MemoryPointer.new(:pointer) do |length_p|
            C.plist_to_xml(self, plist_xml_p, length_p)
            length = length_p.read_uint32
            if plist_xml_p.null?
              return nil
            else
              ptr = plist_xml_p.read_pointer
              begin
                res = ::Plist.parse_xml(ptr.read_bytes(length))
              ensure
                C.free(ptr)
              end
              return res
            end
          end
        end
      end

    end

    #PLIST_API plist_t plist_new_dict(void);
    attach_function :plist_new_dict, [], Plist_t

    #PLIST_API plist_t plist_new_array(void);
    attach_function :plist_new_array, [], Plist_t

    #PLIST_API plist_t plist_new_string(const char *val);
    attach_function :plist_new_string, [:string], Plist_t

    #PLIST_API plist_t plist_new_bool(uint8_t val);
    attach_function :plist_new_bool, [:bool], Plist_t

    #PLIST_API plist_t plist_new_uint(uint64_t val);
    attach_function :plist_new_uint, [:uint64], Plist_t

    #PLIST_API plist_t plist_new_real(double val);
    attach_function :plist_new_real, [:double], Plist_t

    #PLIST_API plist_t plist_new_data(const char *val, uint64_t length);
    attach_function :plist_new_data, [:pointer, :uint64], Plist_t

    #PLIST_API plist_t plist_new_date(int32_t sec, int32_t usec);
    attach_function :plist_new_date, [:int32, :int32], Plist_t

    #PLIST_API plist_t plist_new_uid(uint64_t val);
    attach_function :plist_new_uid, [:uint64], Plist_t

    #PLIST_API plist_t plist_copy(plist_t node);
    attach_function :plist_copy, [Plist_t], Plist_t

    #PLIST_API uint32_t plist_array_get_size(plist_t node);
    attach_function :plist_array_get_size, [Plist_t], :uint32

    #PLIST_API plist_t plist_array_get_item(plist_t node, uint32_t n);
    attach_function :plist_array_get_item, [Plist_t, :uint32], Plist_t

    #PLIST_API uint32_t plist_array_get_item_index(plist_t node);
    attach_function :plist_array_get_item_index, [Plist_t], :uint32

    #PLIST_API void plist_array_set_item(plist_t node, plist_t item, uint32_t n);
    attach_function :plist_array_set_item, [Plist_t, Plist_t, :uint32], :void

    #PLIST_API void plist_array_append_item(plist_t node, plist_t item);
    attach_function :plist_array_append_item, [Plist_t, Plist_t], :void

    #PLIST_API void plist_array_insert_item(plist_t node, plist_t item, uint32_t n);
    attach_function :plist_array_insert_item, [Plist_t, Plist_t, :uint32], :void

    #PLIST_API void plist_array_remove_item(plist_t node, uint32_t n);
    attach_function :plist_array_remove_item, [Plist_t, :uint32], :void

    #PLIST_API uint32_t plist_dict_get_size(plist_t node);
    attach_function :plist_dict_get_size, [Plist_t], :uint32

    typedef :pointer, :plist_dict_iter

    #PLIST_API void plist_dict_new_iter(plist_t node, plist_dict_iter *iter);
    attach_function :plist_dict_new_iter, [Plist_t, :plist_dict_iter], :void

    #PLIST_API void plist_dict_next_item(plist_t node, plist_dict_iter iter, char **key, plist_t *val);
    attach_function :plist_dict_next_item, [Plist_t, :plist_dict_iter, :pointer, :pointer], :void

    #PLIST_API void plist_dict_get_item_key(plist_t node, char **key);
    attach_function :plist_dict_get_item_key, [Plist_t, :pointer], :void

    #PLIST_API plist_t plist_dict_get_item(plist_t node, const char* key);
    attach_function :plist_dict_get_item, [Plist_t, :string], Plist_t

    #PLIST_API void plist_dict_set_item(plist_t node, const char* key, plist_t item);
    attach_function :plist_dict_set_item, [Plist_t, :string, Plist_t], :void

    #PLIST_API void plist_dict_insert_item(plist_t node, const char* key, plist_t item);
    attach_function :plist_dict_insert_item, [Plist_t, :string, Plist_t], :void

    #PLIST_API void plist_dict_remove_item(plist_t node, const char* key);
    attach_function :plist_dict_remove_item, [Plist_t, :string], :void

    #PLIST_API plist_t plist_get_parent(plist_t node);
    attach_function :plist_get_parent, [Plist_t], Plist_t

    typedef enum(
        :BOOLEAN,	  # Boolean, scalar type 
        :UINT,	    # Unsigned integer, scalar type 
        :REAL,	    # Real, scalar type 
        :STRING,	  # ASCII string, scalar type 
        :ARRAY,	    # Ordered array, structured type 
        :DICT,	    # Unordered dictionary (key/value pair), structured type 
        :DATE,	    # Date, scalar type 
        :DATA,	    # Binary data, scalar type 
        :KEY,	      # Key in dictionaries (ASCII String), scalar type 
        :UID,       # Special type used for 'keyed encoding' 
        :NONE,      # No type 
    ), :plist_type

    #PLIST_API plist_type plist_get_node_type(plist_t node);
    attach_function :plist_get_node_type, [Plist_t], :plist_type

    #PLIST_API void plist_get_key_val(plist_t node, char **val);
    attach_function :plist_get_key_val, [Plist_t, :pointer], :void

    #PLIST_API void plist_get_string_val(plist_t node, char **val);
    attach_function :plist_get_string_val, [Plist_t, :pointer], :void

    #PLIST_API void plist_get_bool_val(plist_t node, uint8_t * val);
    attach_function :plist_get_bool_val, [Plist_t, :pointer], :void

    #PLIST_API void plist_get_uint_val(plist_t node, uint64_t * val);
    attach_function :plist_get_uint_val, [Plist_t, :pointer], :void

    #PLIST_API void plist_get_real_val(plist_t node, double *val);
    attach_function :plist_get_real_val, [Plist_t, :pointer], :void

    #PLIST_API void plist_get_data_val(plist_t node, char **val, uint64_t * length);
    attach_function :plist_get_data_val, [Plist_t, :pointer, :pointer], :void

    #PLIST_API void plist_get_date_val(plist_t node, int32_t * sec, int32_t * usec);
    attach_function :plist_get_date_val, [Plist_t, :pointer, :pointer], :void

    #PLIST_API void plist_get_uid_val(plist_t node, uint64_t * val);
    attach_function :plist_get_uid_val, [Plist_t, :pointer], :void

    #PLIST_API void plist_set_type(plist_t node, plist_type type);
    attach_function :plist_set_type, [Plist_t, :plist_type], :void

    #PLIST_API void plist_set_key_val(plist_t node, const char *val);
    attach_function :plist_set_key_val, [Plist_t, :string], :void

    #PLIST_API void plist_set_string_val(plist_t node, const char *val);
    attach_function :plist_set_string_val, [Plist_t, :string], :void

    #PLIST_API void plist_set_bool_val(plist_t node, uint8_t val);
    attach_function :plist_set_bool_val, [Plist_t, :uint8], :void

    #PLIST_API void plist_set_uint_val(plist_t node, uint64_t val);
    attach_function :plist_set_uint_val, [Plist_t, :uint64], :void

    #PLIST_API void plist_set_real_val(plist_t node, double val);
    attach_function :plist_set_real_val, [Plist_t, :double], :void

    #PLIST_API void plist_set_data_val(plist_t node, const char *val, uint64_t length);
    attach_function :plist_set_data_val, [Plist_t, :string, :uint64], :void

    #PLIST_API void plist_set_date_val(plist_t node, int32_t sec, int32_t usec);
    attach_function :plist_set_date_val, [Plist_t, :int32, :int32], :void

    #PLIST_API void plist_set_uid_val(plist_t node, uint64_t val);
    attach_function :plist_set_uid_val, [Plist_t, :int32, :int32], :void

    # void plist_from_bin(const char *plist_bin, uint32_t length, plist_t * plist);
    attach_function :plist_from_bin, [:pointer, :uint32, :pointer], :void

    # void plist_from_xml(const char *plist_xml, uint32_t length, plist_t * plist);
    attach_function :plist_from_xml, [:pointer, :uint32, :pointer], :void

    # void plist_to_bin(plist_t plist, char **plist_bin, uint32_t * length);
    attach_function :plist_to_bin, [Plist_t, :pointer, :pointer], :void

    # void plist_to_xml(plist_t plist, char **plist_xml, uint32_t * length);
    attach_function :plist_to_xml, [Plist_t, :pointer, :pointer], :void

    attach_function :plist_free, [Plist_t], :void


    #----------------------------------------------------------------------
    ffi_lib 'imobiledevice'

    #
    # libimobiledevice.h
    #

    typedef :pointer, :idevice_t
    typedef :pointer, :idevice_connection_t

    typedef enum(
      :SUCCESS,               0,
      :INVALID_ARG,          -1,
      :UNKNOWN_ERROR,        -2,
      :NO_DEVICE,            -3,
      :NOT_ENOUGH_DATA,      -4,
      :BAD_HEADER,           -5,
      :SSL_ERROR,            -6,
    ), :idevice_error_t

    # discovery (synchronous)
    attach_function :idevice_set_debug_level, [:int], :void
    attach_function :idevice_get_device_list, [:pointer, :pointer], :idevice_error_t
    attach_function :idevice_device_list_free, [:pointer], :idevice_error_t

    # device structure creation and destruction
    attach_function :idevice_new, [:pointer, :string], :idevice_error_t
    attach_function :idevice_free, [:pointer], :idevice_error_t

    # connection/disconnection
    attach_function :idevice_connect, [:idevice_t, :uint16, :pointer], :idevice_error_t
    attach_function :idevice_disconnect, [:idevice_connection_t], :idevice_error_t

    # communication
    attach_function :idevice_connection_send, [:idevice_connection_t, :pointer, :uint32, :pointer], :idevice_error_t
    attach_function :idevice_connection_receive_timeout, [:idevice_connection_t, :pointer, :uint32, :pointer, :uint], :idevice_error_t
    attach_function :idevice_connection_receive, [:idevice_connection_t, :pointer, :uint32, :pointer], :idevice_error_t

    # misc
    attach_function :idevice_get_handle, [:idevice_t, :pointer], :idevice_error_t
    attach_function :idevice_get_udid, [:idevice_t, :pointer], :idevice_error_t

    #
    # lockdownd.h
    #

    typedef enum(
      :SUCCESS                  ,  0,
      :INVALID_ARG              , -1,
      :INVALID_CONF             , -2,
      :PLIST_ERROR              , -3,
      :PAIRING_FAILED           , -4,
      :SSL_ERROR                , -5,
      :DICT_ERROR               , -6,
      :START_SERVICE_FAILED     , -7,
      :NOT_ENOUGH_DATA          , -8,
      :SET_VALUE_PROHIBITED     , -9,
      :GET_VALUE_PROHIBITED     ,-10,
      :REMOVE_VALUE_PROHIBITED  ,-11,
      :MUX_ERROR                ,-12,
      :ACTIVATION_FAILED        ,-13,
      :PASSWORD_PROTECTED       ,-14,
      :NO_RUNNING_SESSION       ,-15,
      :INVALID_HOST_ID          ,-16,
      :INVALID_SERVICE          ,-17,
      :INVALID_ACTIVATION_RECORD,-18,
      :UNKNOWN_ERROR            ,-256,
    ), :lockdownd_error_t

    typedef :pointer, :lockdownd_client_t

    class LockdowndPairRecord < FFI::Struct
      layout( :device_certificate,    :string,
              :host_certificate,      :string,
              :host_id,               :string,
              :root_certificate,      :string )
    end

    class LockdowndServiceDescriptor < FFI::ManagedStruct
      layout( :port,        :uint16,
              :ssl_enabled, :uint8 )

      def self.release(ptr)
        ::Idev::C.lockdownd_service_descriptor_free(ptr)
      end
    end

    #lockdownd_error_t lockdownd_client_new(idevice_t device, lockdownd_client_t *client, const char *label);
    attach_function :lockdownd_client_new, [:idevice_t, :pointer, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_client_new_with_handshake(idevice_t device, lockdownd_client_t *client, const char *label);
    attach_function :lockdownd_client_new_with_handshake, [:idevice_t, :pointer, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_client_free(lockdownd_client_t client);
    attach_function :lockdownd_client_free, [:lockdownd_client_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_query_type(lockdownd_client_t client, char **type);
    attach_function :lockdownd_query_type, [:lockdownd_client_t, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_get_value(lockdownd_client_t client, const char *domain, const char *key, plist_t *value);
    attach_function :lockdownd_get_value, [:lockdownd_client_t, :string, :string, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_set_value(lockdownd_client_t client, const char *domain, const char *key, plist_t value);
    attach_function :lockdownd_set_value, [:lockdownd_client_t, :string, :string, Plist_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_remove_value(lockdownd_client_t client, const char *domain, const char *key);
    attach_function :lockdownd_remove_value, [:lockdownd_client_t, :string, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_start_service(lockdownd_client_t client, const char *identifier, lockdownd_service_descriptor_t *service);
    attach_function :lockdownd_start_service, [:lockdownd_client_t, :string, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_start_session(lockdownd_client_t client, const char *host_id, char **session_id, int *ssl_enabled);
    attach_function :lockdownd_start_session, [:lockdownd_client_t, :string, :pointer, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_stop_session(lockdownd_client_t client, const char *session_id);
    attach_function :lockdownd_stop_session, [:lockdownd_client_t, :string], :lockdownd_error_t

    #lockdownd_error_t lockdownd_send(lockdownd_client_t client, plist_t plist);
    attach_function :lockdownd_send, [:lockdownd_client_t, Plist_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_receive(lockdownd_client_t client, plist_t *plist);
    attach_function :lockdownd_receive, [:lockdownd_client_t, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_pair(lockdownd_client_t client, lockdownd_pair_record_t pair_record);
    attach_function :lockdownd_pair, [:lockdownd_client_t, LockdowndPairRecord], :lockdownd_error_t

    #lockdownd_error_t lockdownd_validate_pair(lockdownd_client_t client, lockdownd_pair_record_t pair_record);
    attach_function :lockdownd_validate_pair, [:lockdownd_client_t, LockdowndPairRecord], :lockdownd_error_t

    #lockdownd_error_t lockdownd_unpair(lockdownd_client_t client, lockdownd_pair_record_t pair_record);
    attach_function :lockdownd_unpair, [:lockdownd_client_t, LockdowndPairRecord], :lockdownd_error_t

    #lockdownd_error_t lockdownd_activate(lockdownd_client_t client, plist_t activation_record);
    attach_function :lockdownd_activate, [:lockdownd_client_t, Plist_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_deactivate(lockdownd_client_t client);
    attach_function :lockdownd_deactivate, [:lockdownd_client_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_enter_recovery(lockdownd_client_t client);
    attach_function :lockdownd_enter_recovery, [:lockdownd_client_t], :lockdownd_error_t

    #lockdownd_error_t lockdownd_goodbye(lockdownd_client_t client);
    attach_function :lockdownd_goodbye, [:lockdownd_client_t], :lockdownd_error_t

    #void lockdownd_client_set_label(lockdownd_client_t client, const char *label);
    attach_function :lockdownd_client_set_label, [:lockdownd_client_t, :string], :void

    #lockdownd_error_t lockdownd_get_device_udid(lockdownd_client_t control, char **udid);
    attach_function :lockdownd_get_device_udid, [:lockdownd_client_t, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_get_device_name(lockdownd_client_t client, char **device_name);
    attach_function :lockdownd_get_device_name, [:lockdownd_client_t, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_get_sync_data_classes(lockdownd_client_t client, char ***classes, int *count);
    attach_function :lockdownd_get_sync_data_classes, [:lockdownd_client_t, :pointer, :pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_data_classes_free(char **classes);
    attach_function :lockdownd_data_classes_free, [:pointer], :lockdownd_error_t

    #lockdownd_error_t lockdownd_service_descriptor_free(lockdownd_service_descriptor_t service);
    attach_function :lockdownd_service_descriptor_free, [LockdowndServiceDescriptor], :lockdownd_error_t


    #
    # afc.h
    #

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
    attach_function :afc_client_new, [:idevice_t, LockdowndServiceDescriptor, :pointer], :afc_error_t

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

