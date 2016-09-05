require 'spec_helper'

context 'In Container' do
  context 'In Container' do
    describe file('/etc/fedora-release') do
      it { should be_file }
    end
    describe systemd_unit('hello')  do
      its(:status) { should match /active \(running\)/ }
    end
  end
end
