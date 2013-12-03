#
# Copyright (c) 2013 Eric Monti
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'pathname'
require 'open3'
$SPECROOT = Pathname(__FILE__).dirname
require 'tmpdir'
require 'tempfile'
require 'rubygems'
require 'rspec'
require 'pry'

$LOAD_PATH << $SPECROOT.join("..", "lib").expand_path
require 'idevice'

RSpec.configure do |config|
  def sample_file(filename)
    $SPECROOT.join("samples", filename)
  end

  def relative_paths(paths, reldir)
    paths.map{|p| Pathname(p).relative_path_from(Pathname(reldir)).to_s}
  end

  def spec_logger
    $logger ||=
      if ENV["SPEC_LOGGING"]
        logger = Logger.new($stdout)
        #logger.level = Logger::INFO
        logger
      end
  end

  def shared_idevice
    $shared_idevice ||= Idevice::Idevice.attach
  end

  def shell_pipe(data, cmd)
    ret=nil
    Open3.popen3(cmd) do |w,r,e|
      w.write data
      w.close
      ret = r.read
      r.close
    end
    return ret
  end
end

if ENV["DEBUG"]
  Idevice.debug_level=9
end

if ENV["GC_STRESS"]
  GC.stress = true
end
