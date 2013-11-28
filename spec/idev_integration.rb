require_relative 'spec_helper'

describe Idev do
  it "should list attached devices" do
    devlist = Idev.device_list
    devlist.count.should > 0
    devlist.each do |dev|
      dev.should =~ /^[a-f0-9]{40}$/i
    end
  end

end


