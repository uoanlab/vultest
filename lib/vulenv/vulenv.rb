# Copyright [2019] [University of Aizu]
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

require './lib/vulenv/tools/vagrant'
require './lib/vulenv/tools/ansible'
require './modules/ui'

class Vulenv
  attr_reader :cve, :config, :vulenv_config, :vulenv_dir
  attr_accessor :error

  def initialize(args)
    @cve = args[:cve]
    @config = args[:config]
    @vulenv_config = args[:vulenv_config]
    @vulenv_dir = args[:vulenv_dir]

    FileUtils.mkdir_p(@vulenv_dir)

    @error = { flag: false, cause: nil }
  end

  def create?
    VultestUI.execute('Create vulnerability environment')
    prepare_vagrant
    prepare_ansible

    Dir.chdir(vulenv_dir) do
      error[:cause] = start_up
      return false unless error[:cause].nil?

      error[:cause] = reload if vulenv_config.key?('reload')
      return false unless error[:cause].nil?

      error[:cause] = hard_setup if vulenv_config['construction'].key?('hard_setup')
      return false unless error[:cause].nil?
    end

    prepare_manually_setting if vulenv_config['construction'].key?('prepare')

    error[:cause] = nil
    true
  end

  def destroy!
    Dir.chdir(@vulenv_dir) do
      VultestUI.tty_spinner_begin('Destroy vulnerable environment')
      _stdout, _stderr, status = Open3.capture3('vagrant destroy -f')
      unless status.exitstatus.zero?
        VultestUI.tty_spinner_end('error')
        return false
      end
    end

    _stdout, _stderr, status = Open3.capture3("rm -rf #{@vulenv_dir}")
    unless status.exitstatus.zero?
      VultestUI.tty_spinner_end('error')
      return false
    end

    VultestUI.tty_spinner_end('success')
    true
  end

  private

  def start_up
    VultestUI.tty_spinner_begin('Start up')
    stdout, _stderr, status = Open3.capture3('vagrant up')
    if status.exitstatus.zero?
      VultestUI.tty_spinner_end('success')
      return nil
    end

    VultestUI.tty_spinner_end('error')
    stdout
  end

  def reload
    VultestUI.tty_spinner_begin('Reload')
    stdout, _stderr, status = Open3.capture3('vagrant reload')
    if status.exitstatus.zero?
      VultestUI.tty_spinner_end('success')
      return nil
    end

    VultestUI.tty_spinner_end('error')
    stdout
  end

  def hard_setup
    vulenv_config['construction']['hard_setup']['msg'].each { |msg| puts(" #{msg}") }
    Open3.capture3('vagrant halt')
    TTY::Prompt.new.keypress('Please press enter key, when ready', keys: [:return])
    start_up
  end

  def prepare_manually_setting
    VultestUI.warring('Following execute command')
    puts("  [1] cd #{vulenv_dir}")
    puts('  [2] vagrant ssh')
    vulenv_config['construction']['prepare']['msg'].each.with_index(3) { |msg, i| puts "  [#{i}] #{msg}" }
  end

  def prepare_vagrant
    os_name = vulenv_config['construction']['os']['name']
    os_version = vulenv_config['construction']['os']['version']
    vagrant = Vagrant.new(os_name: os_name, os_version: os_version, env_dir: vulenv_dir)
    vagrant.create
  end

  def prepare_ansible
    ansible = Ansible.new(
      cve: vulenv_config['cve'],
      os_name: vulenv_config['construction']['os']['name'],
      db_path: config['vultest_db_path'],
      attack_vector: vulenv_config['attack_vector'],
      env_config: vulenv_config['construction'],
      env_dir: vulenv_dir
    )
    ansible.create
  end
end
