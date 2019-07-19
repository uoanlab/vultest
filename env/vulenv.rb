# Copyright [2019] [University of Aizu]

#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'bundler/setup'
require 'fileutils'
require 'open3'
require 'tty-table'
require 'tty-prompt'
require 'yaml'

require_relative './params'
require_relative '../build/params'
require_relative './tools/vagrant'
require_relative './tools/ansible'
require_relative '../db'
require_relative '../ui'

class Vulenv
  attr_reader :vulenv_config, :attack_config

  include VulenvParams
  include ConstructionParams

  def initialize(args)
    @config = YAML.load_file('./config.yml')
    @vulenv_dir = args[:vulenv_dir]
    FileUtils.mkdir_p(@vulenv_dir)
    select_vulenv(args[:cve])
  end

  def select_vulenv(cve)
    vul_configs = DB.get_vul_configs(cve)

    if vul_configs.empty?
      puts('Cannot test vulnerability because the software doesn\'t have config file')
      return
    end

    vulenv_table = create_table(vul_configs)
    message = 'Select an id for testing vulnerability envrionment?'
    select_prompt = TTY::Prompt.new
    select_vulenv_name = select_prompt.enum_select(message, vulenv_table[:name_list])

    select_id = vulenv_table[:index_info][select_vulenv_name]

    @vulenv_config = YAML.load_file("#{@config['vultest_db_path']}/#{vul_configs[select_id.to_i - 1]['config_path']}")
    @attack_config = YAML.load_file("#{@config['vultest_db_path']}/#{vul_configs[select_id.to_i - 1]['module_path']}")
  end

  def create
    prepare_vulenv

    VultestUI.print_vultest_message('execute', 'Create vulnerability environment')
    Dir.chdir(@vulenv_dir) do
      start_vulenv
      reload_vulenv if @vulenv_config.key?('reload')
      hard_setup if @vulenv_config['construction'].key?('hard_setup')
    end

    prepare(env_dir: @vulenv_dir, prepare_msg: @vulenv_config['construction']['prepare']['msg']) if @vulenv_config['construction'].key?('prepare')
  end

  def destroy!
    Dir.chdir(@vulenv_dir) do
      VultestUI.tty_spinner_begin('Vulnerable environment destroy')
      _stdout, _stderr, status = Open3.capture3('vagrant destroy -f')
      unless status.exitstatus.zero?
        VultestUI.tty_spinner_end('error')
        return
      end
    end

    _stdout, _stderr, status = Open3.capture3("rm -rf #{@vulenv_dir}")
    unless status.exitstatus.zero?
      VultestUI.tty_spinner_end('error')
      return
    end

    VultestUI.tty_spinner_end('success')
  end

  private

  def create_table(vul_configs)
    table_index = 1
    name_list = []
    table = []
    index_info = {}
    vul_configs.each do |vul_config|
      table.push([table_index, vul_config['name']])
      index_info[vul_config['name']] = table_index
      name_list << vul_config['name']
      table_index += 1
    end

    puts('Vulnerability environment list')
    header = ['id', 'vulenv name']
    table = TTY::Table.new header, table
    table.render(:ascii).each_line do |line|
      puts line.chomp
    end

    { name_list: name_list, index_info: index_info }
  end

  def prepare_vulenv
    create_vagrant
    create_ansible
  end

  def create_vagrant
    os_name = @vulenv_config['construction']['os']['name']
    os_version = @vulenv_config['construction']['os']['version']
    vagrant = Vagrant.new(os_name: os_name, os_version: os_version, env_dir: @vulenv_dir)
    vagrant.create
  end

  def create_ansible
    ansible = Ansible.new(
      cve: @vulenv_config['cve'],
      db_path: @config['vultest_db_path'],
      attack_vector: @vulenv_config['attack_vector'],
      env_config: @vulenv_config['construction'],
      env_dir: @vulenv_dir
    )
    ansible.create
  end
end
