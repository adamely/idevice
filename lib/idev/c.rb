
require "rubygems"
require "ffi"

module Idev
    module C
        extend FFI::Library
        ffi_lib 'imobiledevice'
    end
end

