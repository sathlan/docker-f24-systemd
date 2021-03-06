require 'serverspec'
require 'rspec/retry'
require 'docker'
require 'systemd/journal'

set :backend, :exec

def compose()
  set :os, family: :redhat
  set :backend, :docker
  @image = `docker-compose build`.split(' ')[-1]
  dock_name = `docker-compose up 2>&1 1>/dev/null`.split("\n")[1].split(' ')[-1]
  @container = Docker::Container.get(dock_name)
  set :docker_container, @container.id
end

RSpec.configure do |config|
  # show retry status in spec process
  config.verbose_retry = true
  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  # Set externally in the Rakefile.
  container_id_var_name = "#{ENV['TARGET_HOST'].gsub(/-/,'_').upcase}_ID"
  container_id = ENV[container_id_var_name]

  config.before :all do
    if !ENV['USE_DOCKER'].nil?
      if container_id.nil?
        compose
      else
        set :os, family: :redhat
        set :backend, :docker
        set :docker_container, container_id
      end
    end
    # Have the container id available even for localhost
    @container = Docker::Container.get(container_id) unless container_id.nil?

  end
  config.after :all do
    if !ENV['USE_DOCKER'].nil?
      `docker-compose down` if container_id.nil?
    end
  end
end


def working_os?
  case os[:family]
  when /(?:redhat|fedora)/
    true
  when /ubuntu/
    if Gem::Version.new(os[:release]) >= Gem::Version.new('16.04')
      true
    else
      false
    end
  else
    false
  end
end

module Serverspec::Type
  # This Serverspec type can add and check systemd unit
  class SystemdUnit < Base
    Units = {
      'hello' => <<-eof
[Unit]
Description=Test target

[Service]
ExecStart=/bin/sh -c "while true; do echo Hello World; sleep 1; done"

[Install]
WantedBy=multi-user.target
      eof
    }
    SYSTEMD_PATH='/usr/lib/systemd/system'

    def status
      install_and_run
      @runner.run_command('systemctl status hello').stdout
    end

    private

    def install_and_run
      if @install_and_run.nil?
        unit_file
        unit_file_start
      end
    end

    def unit_file
      content = Units[@name]
      path = ::File.join(SYSTEMD_PATH, "#{@name}.service")
      @runner.run_command("echo '#{content}' | cat - > #{path}")
    end

    def unit_file_start
      @runner.run_command("systemctl start #{@name}")
    end
  end

  def systemd_unit(unit)
    service = SystemdUnit.new(unit)
    service
  end

  class LocalJournal < Base
    def initialize(id)
      @container_id = id
      super
    end
    def content
      c = []
      journal.each do |e|
        c << e.message
      end
      c.join("\n")
    end
    private
    def journal
      return @j if @j
      @j = Systemd::Journal.new()
      @j.filter(CONTAINER_ID_FULL: @container_id)
      @j
    end
  end
  def container_journal(id)
    LocalJournal.new(id)
  end
end

include Serverspec::Type
