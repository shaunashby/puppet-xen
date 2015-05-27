require 'spec_helper'
describe 'xen' do

  context 'with defaults for all parameters' do
    it { should contain_class('xen') }
  end
end
