# Copyright [2020] [University of Aizu]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'bundler/setup'
require 'open3'
require 'tty-prompt'

require './lib/vulenv/vulenv_centos'
require './lib/vulenv/vulenv_ubuntu'
require './lib/vulenv/vulenv_windows'
require './lib/vulenv/tools/vagrant'
require './lib/vulenv/tools/prepare_vagrantfile'
require './lib/vulenv/tools/prepare_ansible'
require './modules/ui'

class ControlVulenv
  attr_reader :cve, :config, :vulenv, :vulenv_config, :vulenv_dir, :vagrant, :error

  def initialize(args)
    @cve = args[:cve]
    @config = args[:config]
    @vulenv_config = args[:vulenv_config]
    @vulenv_dir = args[:vulenv_dir]
    @error = { flag: false, cause: nil }

    @vulenv = case vulenv_config['construction']['os']['name']
              when 'ubuntu' then VulenvUbuntu.new(vulenv_config: @vulenv_config)
              when 'centos' then VulenvCentOS.new(vulenv_config: @vulenv_config)
              when 'windows' then VulnevWindows.new(vulenv_config: @vulenv_config)
              end
  end

  def create?
    VultestUI.execute('Create vulnerability environment')
    prepare

    Dir.chdir(vulenv_dir) do
      { start_up: true, reload: vulenv_config.key?('reload'), hard_setup: vulenv_config['construction'].key?('hard_setup') }.each do |key, value|
        next unless value

        @error[:flag] = !(case key
                          when :start_up then vagrant.start_up?
                          when :reload then vagrant.reload?
                          when :hard_setup then vagrant.hard_setup?(vulenv_config['construction']['hard_setup']['msg'])
                          end)

        next unless @error[:flag]

        @error[:cause] = vagrant.stdout
        return false
      end
    end

    manually_setting if vulenv_config['construction'].key?('prepare')
    true
  end

  def destroy?
    Dir.chdir(vulenv_dir) do
      return false unless @vagrant.destroy!
    end

    VultestUI.tty_spinner_begin("Destroy test_dir(#{vulenv_dir})")
    _stdout, _stderr, status = Open3.capture3("rm -rf #{vulenv_dir}")
    unless status.exitstatus.zero?
      VultestUI.tty_spinner_end('error')
      return false
    end

    VultestUI.tty_spinner_end('success')
    true
  end

  def status_vulenv
    status = vulenv.basic_structure
    return status if error[:flag]

    status.merge!(vulenv.details_structure)
  end

  private

  def manually_setting
    VultestUI.warring('Following execute command')
    puts("  [1] cd #{vulenv_dir}")
    puts('  [2] vagrant ssh')
    vulenv_config['construction']['prepare']['msg'].each.with_index(3) { |msg, i| puts "  [#{i}] #{msg}" }
  end

  def prepare
    FileUtils.mkdir_p(vulenv_dir)
    prepare_vagrant
    prepare_ansible
  end

  def prepare_vagrant
    PrepareVagrantfile.new(os_name: vulenv.os[:name], os_version: vulenv.os[:version], env_dir: vulenv_dir).create
    @vagrant = Vagrant.new
  end

  def prepare_ansible
    PrepareAnsible.new(
      cve: vulenv_config['cve'],
      os_name: vulenv.os[:name],
      db_path: config['vultest_db_path'],
      attack_vector: vulenv_config['attack_vector'],
      env_config: vulenv_config['construction'],
      env_dir: vulenv_dir
    ).create
  end
end
