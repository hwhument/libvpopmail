require_relative "spec_helper.rb"

describe Vpopmail, "#new" do
  it "should return a valid object with default values" do
    vp = Vpopmail.new()
    vp.should be_an_instance_of(Vpopmail)
    vp.dir.should eq "/home/vpopmail/"
  end
end