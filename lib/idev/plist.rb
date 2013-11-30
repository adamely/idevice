require 'idev/c'
require 'plist'

# extensions on the Plist rubygem module for
# working with libplist plist_t objects
module Plist

  def self.xml_to_pointer(xml)
    Idev::Plist_t.from_xml(xml)
  end

  def self.binary_to_pointer(data)
    Idev::Plist_t.from_binary(data)
  end

  def self.parse_binary(data)
    plist_ptr = binary_to_pointer(data)
    if plist_ptr
      res = pointer_to_ruby(plist_ptr)
      return res
    end
  end

  def self.pointer_to_ruby(plist_ptr)
    plist_ptr.to_ruby
  end
end

# common extension for array and hash to convert
# to a libplist plist_t object
module PlistToPointer
  def to_plist_t
    ::Plist.xml_to_pointer(self.to_plist)
  end
end

Array.extend(PlistToPointer)
Hash.extend(PlistToPointer)

module Idev
  class Plist_t < C::ManagedOpaquePointer
    def self.release(ptr)
      C::plist_free(ptr) unless ptr.null?
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


  module C
    ffi_lib 'plist'

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

  end
end
