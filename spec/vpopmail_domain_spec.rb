require_relative "spec_helper.rb"

describe Vpopmail::Domain, "#list" do
  it "should return a array of knwon domains" do
    dlist = Vpopmail::Domain::list()
    puts dlist
    dlist.should be_aninstantce_of(Array)
  end
end