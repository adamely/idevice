require 'idev/c'
require 'idev/idevice'
require 'idev/lockdown'

module Idev
  class AFCError < IdeviceLibError
  end

  def self._handle_afc_error(&block)
    ret = block.call()
    if ret != :SUCCESS
      raise AFCError, "AFC error: #{ret}"
    end
  end

  class AFC < C::ManagedOpaquePointer
    def self.release(ptr)
      C.afc_client_free(ptr) unless ptr.null?
    end

    def self.attach(opts={})
      idevice = opts[:idevice] || Idevice.attach(opts)

      if opts[:appid]
        raise NotImplementedError # XXX TODO house_arrest
      else
        ldsvc = opts[:lockdown_service]
        if ldsvc.nil?
          identifier =
            if opts[:root]
              "com.apple.afc2"
            elsif opts[:afc_identifier]
              opts[:afc_identifier]
            else
              "com.apple.afc"
            end

          ldclient = opts[:lockdown_client] || LockdownClient.attach(opts.merge(idevice:idevice))
          ldsvc = ldclient.start_service(identifier)
        end

        FFI::MemoryPointer.new(:pointer) do |p_afc|
          Idev._handle_afc_error{ C.afc_client_new(idevice, ldsvc, p_afc) }
          afc = p_afc.read_pointer
          raise AFCError, "afc_client_new returned a NULL afc_client_t pointer" if afc.null?
          return new(afc)
        end
      end
    end

    def device_info(key=nil)
      ret = nil
      if key
        FFI::MemoryPointer.new(:pointer) do |p_value|
          Idev._handle_afc_error{ C.afc_get_device_info_key(self, key, p_value) }
          value = p_value.read_pointer
          unless value.null?
            ret = value.read_string
            C.free(value)
          end
        end
      else
        FFI::MemoryPointer.new(:pointer) do |p_infos|
          Idev._handle_afc_error{ C.afc_get_device_info(self, p_infos) }
          ret = _infolist_to_hash(p_infos)
        end
      end
      return ret
    end

    def read_directory(path='.')
      ret = nil
      FFI::MemoryPointer.new(:pointer) do |p_dirlist|
        Idev._handle_afc_error{ C.afc_read_directory(self, path, p_dirlist) }
        ret = _unbound_list_to_array(p_dirlist)
      end
      raise AFCError, "afc_read_directory returned a null directory list for path: #{path}" if ret.nil?
      return ret
    end

    def file_info(path)
      ret = nil
      FFI::MemoryPointer.new(:pointer) do |p_fileinfo|
        Idev._handle_afc_error{ C.afc_get_file_info(self, path, p_fileinfo) }
        ret = _infolist_to_hash(p_fileinfo)
      end
      raise AFCError, "afc_get_file_info returned null info for path: #{path}" if ret.nil?
      return ret
    end

    def make_directory(path)
      Idev._handle_afc_error{ C.afc_make_directory(self, path) }
      return true
    end

    def symlink(from, to)
      Idev._handle_afc_error{ C.afc_make_link(self, :SYMLINK, from, to) }
      return true
    end

    def hardlink(from, to)
      Idev._handle_afc_error{ C.afc_make_link(self, :HARDLINK, from, to) }
      return true
    end

    def rename_path(from, to)
      Idev._handle_afc_error{ C.afc_rename_path(self, from, to) }
      return true
    end

    def remove_path(path)
      Idev._handle_afc_error{ C.afc_remove_path(self, path) }
      return true
    end

    def truncate(path, size)
      Idev._handle_afc_error{ C.afc_truncate(self, path, size) }
      return true
    end

    def cat(path, chunksize=nil, &block)
      AFCFile.open(self, path, 'r') { |f| return f.read_all(chunksize, &block) }
    end

    def putpath(frompath, topath, chunksize=nil)
      chunksize ||= 8192
      wlen = 0

      File.open(frompath, 'r') do |from|
        AFCFile.open(self, topath, 'w') do |to|
          while chunk = from.read(chunksize)
            to.write(chunk)
            yield chunk.size if block_given?
            wlen+=chunk.size
          end
        end
      end

      return wlen
    end

    def getpath(frompath, topath, chunksize=nil)
      wlen = 0
      AFCFile.open(self, frompath, 'r') do |from|
        File.open(topath, 'w') do |to|
          from.read_all(chunksize) do |chunk|
            to.write(chunk)
            yield chunk.size if block_given?
            wlen += chunk.size
          end
        end
      end
      return wlen
    end

    def set_file_time(path, time)
      raise NotImplementedError # XXX TODO
    end

    private
    def _unbound_list_to_array(p_unbound_list)
      ret = nil
      base = list = p_unbound_list.read_pointer
      unless list.null?
        ret = []
        until list.read_pointer.null?
          ret << list.read_pointer.read_string
          list += FFI::TypeDefs[:pointer].size
        end
        C.idevice_device_list_free(base)
      end
      return ret
    end

    def _infolist_to_hash(p_infolist)
      infolist = _unbound_list_to_array(p_infolist)
      if infolist
        return Hash[ infolist.each_slice(2).to_a ]
      end
    end
  end

  class AFCFile
    def self.open(afcclient, path, mode=:RDONLY)
      m = case mode
          when Symbol
            mode
          when 'r'
            :RDONLY
          when 'r+'
            :RW
          when 'w'
            :WRONLY
          when 'w+'
            :WR
          when 'a'
            :APPEND
          when 'a+'
            :RDAPPEND
          else
            raise ArgumentError, "invalid file mode: #{mode.inspect}"
          end

      afcfile=nil
      FFI::MemoryPointer.new(:uint64) do |p_handle|
        Idev._handle_afc_error{ C.afc_file_open(afcclient, path, m, p_handle) }
        afcfile = new(afcclient, p_handle.read_uint64)
      end

      begin
        yield(afcfile)
      ensure
        afcfile.close unless afcfile.closed?
      end
    end

    def initialize(afcclient, handle)
      @afcclient = afcclient
      @handle = handle
      @closed = false
    end

    def close
      Idev._handle_afc_error{ C.afc_file_close(@afcclient, @handle) }
      @closed = true
    end

    def closed?
      @closed == true
    end

    def open?
      not closed?
    end

    def lock(op)
      Idev._handle_afc_error{ C.afc_file_lock(@afcclient, @handle, op) }
      return true
    end

    def seek(offset, whence)
      Idev._handle_afc_error{ C.afc_file_seek(@afcclient, @handle, offset, whence) }
    end

    def tell
      FFI::MemoryPointer.new(:pointer) do |p_pos|
        Idev._handle_afc_error{ C.afc_file_tell(@afcclient, @handle, p_pos) }
        return p_pos.read_uint16
      end
    end
    alias :pos :tell

    def pos=(offset)
      seek(offset, :SEEK_SET)
    end

    def rewind
      self.pos=0
    end

    def read_all(chunksz=nil)
      chunksz ||= 8192
      ret = nil
      FFI::MemoryPointer.new(chunksz) do |buf|
        FFI::MemoryPointer.new(:uint32) do |p_rlen|
          while (err=C.afc_file_read(@afcclient, @handle, buf, buf.size, p_rlen)) == :SUCCESS
            rlen = p_rlen.read_uint32
            chunk = buf.read_bytes(rlen)
            if block_given?
              yield chunk
            else
              ret ||= StringIO.new unless block_given?
              ret << chunk
            end
            break if rlen == 0
          end
          Idev._handle_afc_error{ err } unless [:SUCCESS,:END_OF_DATA].include?(err)
        end
      end

      return ret.string unless ret.nil?
    end

    def read(len=nil, &block)
      return read_all(nil, &block) if len.nil?

      ret = nil

      FFI::MemoryPointer.new(len) do |buf|
        FFI::MemoryPointer.new(:uint32) do |p_rlen|
          while (err=C.afc_file_read(@afcclient, @handle, buf, len, p_rlen) == :SUCCESS)
            rlen = p_rlen.read_uint32
            ret ||= StringIO.new
            ret << buf.read_bytes(rlen)
            len -= rlen
            break if len <= 0
          end
          Idev._handle_afc_error{ err } unless [:SUCCESS, :END_OF_DATA].include?(err)
        end
      end

      return ret.string unless ret.nil?
    end

    def write(data)
      bytes_written = 0
      FFI::MemoryPointer.from_bytes(data) do |p_data|
        FFI::MemoryPointer.new(:uint32) do |p_wlen|
          while bytes_written < p_data.size
            Idev._handle_afc_error{ C.afc_file_write(@afcclient, @handle, p_data, p_data.size, p_wlen) }
            wlen = p_wlen.read_uint32
            p_data += wlen
            bytes_written += wlen
          end
        end
      end
      return bytes_written
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
    attach_function :afc_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :afc_error_t

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
    attach_function :afc_file_write, [:afc_client_t, :uint64, :pointer, :uint32, :pointer], :afc_error_t

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
