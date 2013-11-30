require 'pathname'
$SPECROOT = Pathname(__FILE__).dirname
require 'tmpdir'
require 'tempfile'
require 'rubygems'
require 'rspec'
require 'pry'

$LOAD_PATH << $SPECROOT.join("..", "lib").expand_path
require 'idev'

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
end

if ENV["DEBUG"]
  Idev.debug_level=9
end
