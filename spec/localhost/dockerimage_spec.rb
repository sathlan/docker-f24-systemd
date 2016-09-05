require 'spec_helper'

describe 'Docker image' do
  describe docker_image(ENV['DOCKER_IMAGE']) do
    its(['Architecture']) { should eq 'amd64' }
  end
end
