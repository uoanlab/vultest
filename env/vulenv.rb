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

require_relative '../db'
require_relative '../utility'
require_relative './tools/vagrant'
require_relative './tools/ansible'

class Vulenv
  attr_reader vulenv_config, attack_config

  def initialize(cve, vulenv_dir)
    @config = Utility.get_config
    @vulenv_dirr = vulenv_dir
    FileUtils.mkdir_p(@vulenv_dir)

    select(cve)
  end

  def create
    create_vagrant
    create_ansible

    Utility.print_message('execute', 'Create vulnerability environment')
    Dir.chdir(@vulenv_dir) do
      Utility.tty_spinner_begin('Start up')
      start_vulenv == 'success' ? Utility.tty_spinner_end('success') : Utility.tty_spinner_end('error')

      if @vulenv_config.key?('reload')
        Utility.tty_spinner_begin('Reload')
        reload_vulenv == 'success' ? Utility.tty_spinner_end('success') : Utility.tty_spinner_end('error')
      end

      if vulenv_config['construction'].key?('hard_setup')
        vulenv_config['construction']['hard_setup']['msg'].each { |msg| Utility.print_message('caution', msg) }
        Open3.capture3('vagrant halt')

        puts('Please enter key when ready')
        gets

        Utility.tty_spinner_begin('Reload')
        hard_setup == 'success' ? Utility.tty_spinner_end('success') : Utility.tty_spinner_end('error')
      end
    end
  end

  def destroy!
    Dir.chdir(@vulenv_dir) do
      Utility.tty_spinner_begin('Vulnerable environment destroy')
      _stdout, _stderr, status = Open3.capture3('vagrant destroy -f')
      unless status.exitstatus.zero?
        Utility.tty_spinner_end('error')
        return
      end
    end

    _stdout, _stderr, status = Open3.capture3("rm -rf #{vulenv_dir}")
    unless status.exitstatus.zero?
      Utility.tty_spinner_end('error')
      return
    end
    Utility.tty_spinner_end('success')
  end

  class << self
    def select(cve)
      vul_configs = DB.get_vul_configs(cve)

      if vul_configs.empty?
        puts('Cannot test vulnerability because the software doesn\'t have config file')
        return
      end

      vulenv_table = create_table
      message = 'Select an id for testing vulnerability envrionment?'
      select_vulenv_name = Utility.tty_prompt(message, vulenv_table[:name_list])
      select_id = vulenv_index_info[:index_info][select_vulenv_name]

      @vulenv_config = YAML.load_file("#{config['vultest_db_path']}/#{vul_configs[select_id.to_i - 1]['config_path']}")
      @attack_config = YAML.load_file("#{config['vultest_db_path']}/#{vul_configs[select_id.to_i - 1]['module_path']}")
    end

    def create_table
      name_list = []
      table = []
      index_info = {}
      vul_configs.each do |vul_config|
        table.push([table_index, vul_config['name']])
        index_info[vul_config['name']] = table_index
        name_list << vul_config['name']
      end

      puts('Vulnerability environment list')
      header = ['id', 'vulenv name']
      table = TTY::Table.new header, table
      table.render(:ascii).each_line do |line|
        puts line.chomp
      end

      { name_list: name_list, index_info: index_info }
    end

    def create_vagrant
      puts 'vagrant'
    end

    def create_ansible
      puts 'heeloo'
    end

    def start_vulenv
      _stdout, _stderr, status = Open3.capture3('vagrant up')
      reload_vulenv unless status.exitstatus.zero?

      'success'
    end

    def reload_vulenv
      _stdout, _stderr, status = Open3.capture3('vagrant reload')
      return 'error' unless status.exitstatus.zero?

      'success'
    end

    def hard_setup
      @vulenv_config['construction']['hard_setup']['msg'].each { |msg| Utility.print_message('caution', msg) }
      Open3.capture3('vagrant halt')

      puts('Please enter key when ready')
      gets

      Utility.tty_spinner_begin('Reload')
      start_vulenv
    end
  end
end
