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

module Vulenv

  def create(vulenv_config_path, vulenv_dir)

    FileUtils.mkdir_p(vulenv_dir)
    Vagrant.create(vulenv_config_path, vulenv_dir)
    Ansible.create(vulenv_config_path, vulenv_dir)

    vulenv_config = YAML.load_file(vulenv_config_path)

    Utility.print_message('execute', 'Create vulnerability environment')
    Dir.chdir(vulenv_dir) do
      Utility.tty_spinner_begin('Start up')
      stdout, stderr, status = Open3.capture3('vagrant up')

      if status.exitstatus != 0
        reload_stdout, reload_stderr, reload_status = Open3.capture3('vagrant reload')

        if reload_status.exitstatus != 0
          Utility.tty_spinner_end('error')
          return 'error'
        end
      end

      if vulenv_config.key?('reload')
        reload_status, reload_stderr, reload_status = Open3.capture3('vagrant reload')
        if reload_status.exitstatus != 0 
          Utility.tty_spinner_end('error')
          return 'error'
        end
      end

      Utility.tty_spinner_end('success')

      if vulenv_config['construction'].key?('hard_setup')
        vulenv_config['construction']['hard_setup']['msg'].each { |msg| Utility.print_message('caution', msg) }
        Open3.capture3('vagrant halt')

        Utility.print_message('default','Please enter key when ready')
        input = gets

        Utility.tty_spinner_begin('Reload')
        stdout, stderr, status = Open3.capture3('vagrant up')
        if status.exitstatus != 0
          Utility.tty_spinner_end('error')
          return 'error'
        end
        Utility.tty_spinner_end('success')
      end
    end
  end

  def destroy(vulenv_dir)
    Dir.chdir(vulenv_dir) do
      Utility.tty_spinner_begin('Vulnerable environment destroy')
      stdout, stderr, status = Open3.capture3('vagrant destroy -f')
      if status.exitstatus != 0
        Utility.tty_spinner_end('error')
        exit!
      end
    end

    stdout, stderr, status = Open3.capture3("rm -rf #{vulenv_dir}")
    if status.exitstatus != 0
      Utility.tty_spinner_end('error')
      exit!
    end

    Utility.tty_spinner_end('success')
  end

  def select(cve)
    vul_configs = DB.get_vul_configs(cve)

    table_index = 1
    vulenv_name_list = []
    vulenv_table = []
    vulenv_index_info = {}
    vul_configs.each do |vul_config|
      vulenv_table.push([table_index, vul_config['name']])
      vulenv_index_info[vul_config['name']] = table_index
      vulenv_name_list << vul_config['name']
      table_index += 1
    end

    return nil, nil if table_index == 1

    Utility.print_message('output', 'Vulnerability environment list')
    header = ['id', 'vulenv name']
    table = TTY::Table.new header, vulenv_table
    table.render(:ascii).each_line do |line|
      puts line.chomp
    end
    print "\n"

    message = 'Select an id for testing vulnerability envrionment?'
    select_vulenv_name = Utility.tty_prompt(message, vulenv_name_list)
    select_id = vulenv_index_info[select_vulenv_name]

    config = Utility.get_config

    vulenv_config_path = "#{config['vultest_db_path']}/#{vul_configs[select_id.to_i - 1]['config_path']}"
    attack_config_path = "#{config['vultest_db_path']}/#{vul_configs[select_id.to_i - 1]['module_path']}"

    return vulenv_config_path, attack_config_path
  end

  module_function :create
  module_function :select
  module_function :destroy
end
