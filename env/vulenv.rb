=begin
Copyright [2019] [Kohei Akasaka]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Copyright © 2008 Jamis Buck
Relased under the MIT license
https://github.com/net-ssh/net-ssh/blob/master/LICENSE.txt

Copyright (c) Marcin Kulik
Relased under the MIT license
https://github.com/sickill/rainbow/blob/master/LICENSE

Copyright (c) 2016 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-command/blob/master/LICENSE.txt

Copyright (c) 2015 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-prompt/blob/master/LICENSE.txt

Copyright (c) 2014 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-spinner/blob/master/LICENSE.txt

Copyright (c) 2015 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-table/blob/master/LICENSE.txt

Copyright (c) 2014 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/pastel/blob/master/LICENSE.txt

Copyright (c) 2017 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-font/blob/master/LICENSE.txt

This software includes the work that is distributed in the Apache License 2.0
=end

require_relative '../db'
require_relative '../utility'
require_relative './tools/vagrant'
require_relative './tools/ansible'

module Vulenv

  def create(vulenv_config_path, vulenv_dir)

    # Create the vulnerable environment
    FileUtils.mkdir_p(vulenv_dir)
    Vagrant.create(vulenv_config_path, vulenv_dir)
    Ansible.create(vulenv_config_path, vulenv_dir)

    vulenv_config_detail = YAML.load_file(vulenv_config_path)

    # start up environment of vulnerability
    Utility.print_message('execute', 'create vulnerability environment')
    Dir.chdir(vulenv_dir) do
      Utility.tty_spinner_begin('start up')
      stdout, stderr, status = Open3.capture3('vagrant up')

      if status.exitstatus != 0
        reload_stdout, reload_stderr, reload_status = Open3.capture3('vagrant reload')

        if reload_status.exitstatus != 0
          Utility.tty_spinner_end('error')
          return 'error'
        end
      end

      if vulenv_config_detail.key?('reload')
        reload_status, reload_stderr, reload_status = Open3.capture3('vagrant reload')
        if reload_status.exitstatus != 0 
          Utility.tty_spinner_end('error')
          return 'error'
        end
      end

      Utility.tty_spinner_end('success')

      # When tool cannot change setting, tool want user to change setting
      if vulenv_config_detail['construction'].key?('hard_setup')
        vulenv_caution_setup_flag = false
        vulenv_config_detail['construction']['hard_setup']['msg'].each do |msg|
          Utility.print_message('caution', msg)
        end
        Open3.capture3('vagrant halt')
        vulenv_caution_setup_flag = true

        if vulenv_caution_setup_flag
          Utility.print_message('default','Please enter key when ready')
          input = gets

          Utility.tty_spinner_begin('reload')
          stdout, stderr, status = Open3.capture3('vagrant up')
          if status.exitstatus != 0
            Utility.tty_spinner_end('error')
            return 'error'
          end
          Utility.tty_spinner_end('success')
        end
      end
    end
  end

  def destroy(vulenv_dir)
    Dir.chdir(vulenv_dir) do
      Utility.tty_spinner_begin('vulent destroy')
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
    vulconfigs = DB.get_vulconfigs(cve)

    table_index = 0
    vulenv_name_list = []
    vulenv_table = []
    vulenv_index_info = {}
    vulconfigs.each do |vulconfig|
      vulenv_table.push([table_index, vulconfig['name']])
      vulenv_index_info[vulconfig['name']] = table_index
      vulenv_name_list.push(vulconfig['name'])
      table_index += 1
    end

    return nil, nil if table_index == 0

    # Can create list which is environment of vulnerability
    Utility.print_message('output', 'vulnerability environment list')
    header = ['id', 'vulenv name']
    table = TTY::Table.new header, vulenv_table
    table.render(:ascii).each_line do |line|
      puts line.chomp
    end
    print "\n"

    # Select environment of vulnerability by id
    message = 'Select an id for testing vulnerability envrionment?'
    select_vulenv_name = Utility.tty_prompt(message, vulenv_name_list)
    select_id = vulenv_index_info[select_vulenv_name]

    config = Utility.get_config

    vulenv_config_path = "#{config['vultest_db_path']}/#{vulconfigs[select_id.to_i]['config_path']}"
    attack_config_path = "#{config['vultest_db_path']}/#{vulconfigs[select_id.to_i]['module_path']}"

    return vulenv_config_path, attack_config_path
  end

  module_function :create
  module_function :select
  module_function :destroy
end
