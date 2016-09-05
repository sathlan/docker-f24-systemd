require 'spec_helper'


context 'From host' do
  context 'Docker Daemon' do
    it 'run with the correct options' do
      skip "https://bugzilla.redhat.com/show_bug.cgi?id=1312665 and https://github.com/docker/docker/issues/20798"
      expect(`systemctl status docker`).to match /--userns-remap=default/
    end
  end

  context 'Host journald', retry: 1, retry_wait: 2 do
    it 'expect to see service log' do
      expect(container_journal(@container.id).content).to match /Hello/
    end
  end

  describe command('docker ps') do
    its(:stdout) { should match /#{ENV['DOCKER_IMAGE']}.*\/sbin\/init.* Up/ }
  end
end
