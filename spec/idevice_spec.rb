require_relative 'spec_helper'

describe Idevice do
  it "should have a version" do
    Idevice::VERSION.should be_a String
    Idevice::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end
end

