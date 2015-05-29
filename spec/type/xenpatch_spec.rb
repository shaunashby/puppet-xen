require 'spec_helper'
 
xenpatch_type = Puppet::Type.type(:xenpatch)
 
parameters = [ :name, :source ]
properties = [ :ensure ]
 
describe Puppet::Type.type(:xenpatch) do
 
  before do
    provider_class = xenpatch_type.provider(:xe)
    xenpatch_type.stubs(:defaultprovider).returns provider_class
    @resource = xenpatch_type.new(:name => 'XSSP1025')
  end
 
  it "should accept the 'name' parameter." do
    expect(xenpatch_type.new(:name => 'XSSP1025')[:name]).to eq('XSSP1025')
  end
 
  it "should accept the 'title' and 'name' parameter." do
    expect(xenpatch_type.new(:title => 'A fix for the VENOM vulnerability',
                             :name => 'XSSP1025')[:name]).to eq('XSSP1025')
  end
 
  it "should accept the 'source' parameter." do
    expect(xenpatch_type.new(:title => 'XSSP1025',
                             :source => '/tmp/XSSP1025.xsupdate')[:source]).to eq('/tmp/XSSP1025.xsupdate')
  end
 
  it "should be able to create an instance" do
    expect {
      xenpatch_type.new(:name => "XSSP1025")
    }.not_to raise_error
  end
 
  it "should support :present as a value to :ensure" do
    expect {
      xenpatch_type.new(:name => "XSSP1025", :ensure => :present)
    }.not_to raise_error
  end
 
end
