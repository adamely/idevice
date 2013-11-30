require_relative 'spec_helper'

describe Idev do
  it "should have a version" do
    Idev::VERSION.should be_a String
    Idev::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end
end

