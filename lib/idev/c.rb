
require "rubygems"
require "ffi"

module FFI
  class Pointer
    def read_unbound_array_of_string
      #Reads an array of strings terminated by an empty string (i.e.
      #not length bound
      ary = []
      size = FFI.type_size(:string)
      tmp = self
      begin
        s = tmp.read_pointer.read_string
        ary << s
        tmp += size
      end while !tmp.read_pointer.null?
      ary
    end
  end

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

    typedef :pointer, :plist_t

    #/**
    # * Create a new root plist_t type #PLIST_DICT
    # *
    # * @return the created plist
    # * @sa #plist_type
    # */
    #PLIST_API plist_t plist_new_dict(void);
    attach_function :plist_new_dict, [], :plist_t

    #/**
    # * Create a new root plist_t type #PLIST_ARRAY
    # *
    # * @return the created plist
    # * @sa #plist_type
    # */
    #PLIST_API plist_t plist_new_array(void);
    attach_function :plist_new_array, [], :plist_t

    #/**
    # * Create a new plist_t type #PLIST_STRING
    # *
    # * @param val the sting value, encoded in UTF8.
    # * @return the created item
    # * @sa #plist_type
    # */
    #PLIST_API plist_t plist_new_string(const char *val);
    attach_function :plist_new_string, [:string], :plist_t

    #/**
    # * Create a new plist_t type #PLIST_BOOLEAN
    # *
    # * @param val the boolean value, 0 is false, other values are true.
    # * @return the created item
    # * @sa #plist_type
    # */
    #PLIST_API plist_t plist_new_bool(uint8_t val);
    attach_function :plist_new_bool, [:uint8], :plist_t

    #/**
    # * Create a new plist_t type #PLIST_UINT
    # *
    # * @param val the unsigned integer value
    # * @return the created item
    # * @sa #plist_type
    # */
    #PLIST_API plist_t plist_new_uint(uint64_t val);
    attach_function :plist_new_uint, [:uint64], :plist_t

    #/**
    # * Create a new plist_t type #PLIST_REAL
    # *
    # * @param val the real value
    # * @return the created item
    # * @sa #plist_type
    # */
    #PLIST_API plist_t plist_new_real(double val);
    attach_function :plist_new_real, [:double], :plist_t

    #/**
    # * Create a new plist_t type #PLIST_DATA
    # *
    # * @param val the binary buffer
    # * @param length the length of the buffer
    # * @return the created item
    # * @sa #plist_type
    # */
    #PLIST_API plist_t plist_new_data(const char *val, uint64_t length);
    attach_function :plist_new_data, [:pointer, :uint64], :plist_t

    #/**
    # * Create a new plist_t type #PLIST_DATE
    # *
    # * @param sec the number of seconds since 01/01/2001
    # * @param usec the number of microseconds
    # * @return the created item
    # * @sa #plist_type
    # */
    #PLIST_API plist_t plist_new_date(int32_t sec, int32_t usec);
    attach_function :plist_new_date, [:int32, :int32], :plist_t

    #/**
    # * Create a new plist_t type #PLIST_UID
    # *
    # * @param val the unsigned integer value
    # * @return the created item
    # * @sa #plist_type
    # */
    #PLIST_API plist_t plist_new_uid(uint64_t val);
    attach_function :plist_new_uid, [:uint64], :plist_t

    #/**
    # * Return a copy of passed node and it's children
    # *
    # * @param node the plist to copy
    # * @return copied plist
    # */
    #PLIST_API plist_t plist_copy(plist_t node);
    attach_function :plist_copy, [:plist_t], :plist_t

    #/**
    # * Get size of a #PLIST_ARRAY node.
    # *
    # * @param node the node of type #PLIST_ARRAY
    # * @return size of the #PLIST_ARRAY node
    # */
    #PLIST_API uint32_t plist_array_get_size(plist_t node);
    attach_function :plist_array_get_size, [:plist_t], :uint32

    #/**
    # * Get the nth item in a #PLIST_ARRAY node.
    # *
    # * @param node the node of type #PLIST_ARRAY
    # * @param n the index of the item to get. Range is [0, array_size[
    # * @return the nth item or NULL if node is not of type #PLIST_ARRAY
    # */
    #PLIST_API plist_t plist_array_get_item(plist_t node, uint32_t n);
    attach_function :plist_array_get_item, [:plist_t, :uint32], :plist_t

    #/**
    # * Get the index of an item. item must be a member of a #PLIST_ARRAY node.
    # *
    # * @param node the node
    # * @return the node index
    # */
    #PLIST_API uint32_t plist_array_get_item_index(plist_t node);
    attach_function :plist_array_get_item_index, [:plist_t], :uint32

    #/**
    # * Set the nth item in a #PLIST_ARRAY node.
    # * The previous item at index n will be freed using #plist_free
    # *
    # * @param node the node of type #PLIST_ARRAY
    # * @param item the new item at index n
    # * @param n the index of the item to get. Range is [0, array_size[. Assert if n is not in range.
    # */
    #PLIST_API void plist_array_set_item(plist_t node, plist_t item, uint32_t n);
    attach_function :plist_array_set_item, [:plist_t, :plist_t, :uint32], :void

    #/**
    # * Append a new item at the end of a #PLIST_ARRAY node.
    # *
    # * @param node the node of type #PLIST_ARRAY
    # * @param item the new item
    # */
    #PLIST_API void plist_array_append_item(plist_t node, plist_t item);
    attach_function :plist_array_append_item, [:plist_t, :plist_t], :void

    #/**
    # * Insert a new item at position n in a #PLIST_ARRAY node.
    # *
    # * @param node the node of type #PLIST_ARRAY
    # * @param item the new item to insert
    # * @param n The position at which the node will be stored. Range is [0, array_size[. Assert if n is not in range.
    # */
    #PLIST_API void plist_array_insert_item(plist_t node, plist_t item, uint32_t n);
    attach_function :plist_array_insert_item, [:plist_t, :plist_t, :uint32], :void

    #/**
    # * Remove an existing position in a #PLIST_ARRAY node.
    # * Removed position will be freed using #plist_free
    # *
    # * @param node the node of type #PLIST_ARRAY
    # * @param n The position to remove. Range is [0, array_size[. Assert if n is not in range.
    # */
    #PLIST_API void plist_array_remove_item(plist_t node, uint32_t n);
    attach_function :plist_array_remove_item, [:plist_t, :uint32], :void

    #/**
    # * Get size of a #PLIST_DICT node.
    # *
    # * @param node the node of type #PLIST_DICT
    # * @return size of the #PLIST_DICT node
    # */
    #PLIST_API uint32_t plist_dict_get_size(plist_t node);
    attach_function :plist_dict_get_size, [:plist_t], :uint32

    typedef :pointer, :plist_dict_iter

    #/**
    # * Create iterator of a #PLIST_DICT node.
    # * The allocated iterator shoult be freed with tandard free function
    # *
    # * @param node the node of type #PLIST_DICT
    # * @param iter iterator of the #PLIST_DICT node
    # */
    #PLIST_API void plist_dict_new_iter(plist_t node, plist_dict_iter *iter);
    attach_function :plist_dict_new_iter, [:plist_t, :plist_dict_iter], :void

    #/**
    # * Increment iterator of a #PLIST_DICT node.
    # *
    # * @param node the node of type #PLIST_DICT
    # * @param iter iterator of the dictionary
    # * @param key a location to store the key, or NULL.
    # * @param val a location to store the value, or NULL.
    # */
    #PLIST_API void plist_dict_next_item(plist_t node, plist_dict_iter iter, char **key, plist_t *val);
    attach_function :plist_dict_next_item, [:plist_t, :plist_dict_iter, :pointer, :pointer], :void

    #/**
    # * Get key associated to an item. Item must be member of a dictionary
    # *
    # * @param node the node
    # * @param key a location to store the key.
    # */
    #PLIST_API void plist_dict_get_item_key(plist_t node, char **key);
    attach_function :plist_dict_get_item_key, [:plist_t, :pointer], :void

    #/**
    # * Get the nth item in a #PLIST_DICT node.
    # *
    # * @param node the node of type #PLIST_DICT
    # * @param key the identifier of the item to get.
    # * @return the item or NULL if node is not of type #PLIST_DICT
    # */
    #PLIST_API plist_t plist_dict_get_item(plist_t node, const char* key);
    attach_function :plist_dict_get_item, [:plist_t, :string], :plist_t

    #/**
    # * Set item identified by key in a #PLIST_DICT node.
    # * The previous item at index n will be freed using #plist_free
    # *
    # * @param node the node of type #PLIST_DICT
    # * @param item the new item associated to key
    # * @param key the identifier of the item to get. Assert if identifier is not present.
    # */
    #PLIST_API void plist_dict_set_item(plist_t node, const char* key, plist_t item);
    attach_function :plist_dict_set_item, [:plist_t, :string, :plist_t], :void

    #/**
    # * Insert a new item at position n in a #PLIST_DICT node.
    # *
    # * @param node the node of type #PLIST_DICT
    # * @param item the new item to insert
    # * @param key The identifier of the item to insert. Assert if identifier already present.
    # */
    #PLIST_API void plist_dict_insert_item(plist_t node, const char* key, plist_t item);
    attach_function :plist_dict_insert_item, [:plist_t, :string, :plist_t], :void

    #/**
    # * Remove an existing position in a #PLIST_DICT node.
    # * Removed position will be freed using #plist_free
    # *
    # * @param node the node of type #PLIST_DICT
    # * @param key The identifier of the item to remove. Assert if identifier is not present.
    # */
    #PLIST_API void plist_dict_remove_item(plist_t node, const char* key);
    attach_function :plist_dict_remove_item, [:plist_t, :string], :void

    #/**
    # * Get the parent of a node
    # *
    # * @param node the parent (NULL if node is root)
    # */
    #PLIST_API plist_t plist_get_parent(plist_t node);
    attach_function :plist_get_parent, [:plist_t], :plist_t

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

    #/**
    # * Get the #plist_type of a node.
    # *
    # * @param node the node
    # * @return the type of the node
    # */
    #PLIST_API plist_type plist_get_node_type(plist_t node);
    attach_function :plist_get_node_type, [:plist_t], :plist_type

    #/**
    # * Get the value of a #PLIST_KEY node.
    # * This function does nothing if node is not of type #PLIST_KEY
    # *
    # * @param node the node
    # * @param val a pointer to a C-string. This function allocates the memory,
    # *            caller is responsible for freeing it.
    # */
    #PLIST_API void plist_get_key_val(plist_t node, char **val);
    attach_function :plist_get_key_val, [:plist_t, :pointer], :void

    #/**
    # * Get the value of a #PLIST_STRING node.
    # * This function does nothing if node is not of type #PLIST_STRING
    # *
    # * @param node the node
    # * @param val a pointer to a C-string. This function allocates the memory,
    # *            caller is responsible for freeing it. Data is UTF-8 encoded.
    # */
    #PLIST_API void plist_get_string_val(plist_t node, char **val);
    attach_function :plist_get_string_val, [:plist_t, :pointer], :void

    #/**
    # * Get the value of a #PLIST_BOOLEAN node.
    # * This function does nothing if node is not of type #PLIST_BOOLEAN
    # *
    # * @param node the node
    # * @param val a pointer to a uint8_t variable.
    # */
    #PLIST_API void plist_get_bool_val(plist_t node, uint8_t * val);
    attach_function :plist_get_bool_val, [:plist_t, :pointer], :void

    #/**
    # * Get the value of a #PLIST_UINT node.
    # * This function does nothing if node is not of type #PLIST_UINT
    # *
    # * @param node the node
    # * @param val a pointer to a uint64_t variable.
    # */
    #PLIST_API void plist_get_uint_val(plist_t node, uint64_t * val);
    attach_function :plist_get_uint_val, [:plist_t, :pointer], :void

    #/**
    # * Get the value of a #PLIST_REAL node.
    # * This function does nothing if node is not of type #PLIST_REAL
    # *
    # * @param node the node
    # * @param val a pointer to a double variable.
    # */
    #PLIST_API void plist_get_real_val(plist_t node, double *val);
    attach_function :plist_get_real_val, [:plist_t, :pointer], :void

    #/**
    # * Get the value of a #PLIST_DATA node.
    # * This function does nothing if node is not of type #PLIST_DATA
    # *
    # * @param node the node
    # * @param val a pointer to an unallocated char buffer. This function allocates the memory,
    # *            caller is responsible for freeing it.
    # * @param length the length of the buffer
    # */
    #PLIST_API void plist_get_data_val(plist_t node, char **val, uint64_t * length);
    attach_function :plist_get_data_val, [:plist_t, :pointer, :pointer], :void

    #/**
    # * Get the value of a #PLIST_DATE node.
    # * This function does nothing if node is not of type #PLIST_DATE
    # *
    # * @param node the node
    # * @param sec a pointer to an int32_t variable. Represents the number of seconds since 01/01/2001.
    # * @param usec a pointer to an int32_t variable. Represents the number of microseconds
    # */
    #PLIST_API void plist_get_date_val(plist_t node, int32_t * sec, int32_t * usec);
    attach_function :plist_get_date_val, [:plist_t, :pointer, :pointer], :void

    #/**
    # * Get the value of a #PLIST_UID node.
    # * This function does nothing if node is not of type #PLIST_UID
    # *
    # * @param node the node
    # * @param val a pointer to a uint64_t variable.
    # */
    #PLIST_API void plist_get_uid_val(plist_t node, uint64_t * val);
    attach_function :plist_get_uid_val, [:plist_t, :pointer], :void

   #/**
    # * Forces type of node. Changing type of structured nodes is only allowed if node is empty.
    # * Reset value of node;
    # * @param node the node
    # * @param type the key value
    # */
    #PLIST_API void plist_set_type(plist_t node, plist_type type);
    attach_function :plist_set_type, [:plist_t, :plist_type], :void

    #/**
    # * Set the value of a node.
    # * Forces type of node to #PLIST_KEY
    # *
    # * @param node the node
    # * @param val the key value
    # */
    #PLIST_API void plist_set_key_val(plist_t node, const char *val);
    attach_function :plist_set_key_val, [:plist_t, :string], :void

    #/**
    # * Set the value of a node.
    # * Forces type of node to #PLIST_STRING
    # *
    # * @param node the node
    # * @param val the string value
    # */
    #PLIST_API void plist_set_string_val(plist_t node, const char *val);
    attach_function :plist_set_string_val, [:plist_t, :string], :void

    #/**
    # * Set the value of a node.
    # * Forces type of node to #PLIST_BOOLEAN
    # *
    # * @param node the node
    # * @param val the boolean value
    # */
    #PLIST_API void plist_set_bool_val(plist_t node, uint8_t val);
    attach_function :plist_set_bool_val, [:plist_t, :uint8], :void

    #/**
    # * Set the value of a node.
    # * Forces type of node to #PLIST_UINT
    # *
    # * @param node the node
    # * @param val the unsigned integer value
    # */
    #PLIST_API void plist_set_uint_val(plist_t node, uint64_t val);
    attach_function :plist_set_uint_val, [:plist_t, :uint64], :void

    #/**
    # * Set the value of a node.
    # * Forces type of node to #PLIST_REAL
    # *
    # * @param node the node
    # * @param val the real value
    # */
    #PLIST_API void plist_set_real_val(plist_t node, double val);
    attach_function :plist_set_real_val, [:plist_t, :double], :void

    #/**
    # * Set the value of a node.
    # * Forces type of node to #PLIST_DATA
    # *
    # * @param node the node
    # * @param val the binary buffer
    # * @param length the length of the buffer
    # */
    #PLIST_API void plist_set_data_val(plist_t node, const char *val, uint64_t length);
    attach_function :plist_set_data_val, [:plist_t, :string, :uint64], :void

    #/**
    # * Set the value of a node.
    # * Forces type of node to #PLIST_DATE
    # *
    # * @param node the node
    # * @param sec the number of seconds since 01/01/2001
    # * @param usec the number of microseconds
    # */
    #PLIST_API void plist_set_date_val(plist_t node, int32_t sec, int32_t usec);
    attach_function :plist_set_date_val, [:plist_t, :int32, :int32], :void

    #/**
    # * Set the value of a node.
    # * Forces type of node to #PLIST_UID
    # *
    # * @param node the node
    # * @param val the unsigned integer value
    # */
    #PLIST_API void plist_set_uid_val(plist_t node, uint64_t val);
    attach_function :plist_set_uid_val, [:plist_t, :int32, :int32], :void

    # * Import the #plist_t structure from binary format.
    # *
    # * @param plist_bin a pointer to the xml buffer.
    # * @param length length of the buffer to read.
    # * @param plist a pointer to the imported plist.
    # */
    # void plist_from_bin(const char *plist_bin, uint32_t length, plist_t * plist);
    attach_function :plist_from_bin, [:pointer, :uint32, :pointer], :void

    #/**
    # * Import the #plist_t structure from XML format.
    # *
    # * @param plist_xml a pointer to the xml buffer.
    # * @param length length of the buffer to read.
    # * @param plist a pointer to the imported plist.
    # */
    # void plist_from_xml(const char *plist_xml, uint32_t length, plist_t * plist);
    attach_function :plist_from_xml, [:pointer, :uint32, :pointer], :void

    #/**
    # * Export the #plist_t structure to binary format.
    # *
    # * @param plist the root node to export
    # * @param plist_bin a pointer to a char* buffer. This function allocates the memory,
    # *            caller is responsible for freeing it.
    # * @param length a pointer to an uint32_t variable. Represents the length of the allocated buffer.
    # */
    # void plist_to_bin(plist_t plist, char **plist_bin, uint32_t * length);
    attach_function :plist_to_bin, [:plist_t, :pointer, :pointer], :void

    #/**
    # * Export the #plist_t structure to XML format.
    # *
    # * @param plist the root node to export
    # * @param plist_xml a pointer to a C-string. This function allocates the memory,
    # *            caller is responsible for freeing it. Data is UTF-8 encoded.
    # * @param length a pointer to an uint32_t variable. Represents the length of the allocated buffer.
    # */
    # void plist_to_xml(plist_t plist, char **plist_xml, uint32_t * length);
    attach_function :plist_to_xml, [:plist_t, :pointer, :pointer], :void

    attach_function :plist_free, [:plist_t], :void


    #----------------------------------------------------------------------
    ffi_lib 'imobiledevice'

    typedef :pointer, :idevice_t
    typedef :pointer, :idevice_connection_t

    IdeviceError = enum(
      :SUCCESS,               0,
      :INVALID_ARG,          -1,
      :UNKNOWN_ERROR,        -2,
      :NO_DEVICE,            -3,
      :NOT_ENOUGH_DATA,      -4,
      :BAD_HEADER,           -5,
      :SSL_ERROR,            -6,
    )

    typedef IdeviceError, :idevice_error_t

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

  end
end

