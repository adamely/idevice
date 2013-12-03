#
# Copyright (c) 2013 Eric Monti - Bluebox Security
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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
