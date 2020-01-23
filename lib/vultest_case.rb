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
require 'tty-table'
require 'tty-prompt'
require 'yaml'

require './lib/db'
require './lib/ui'

class VultestCase
  attr_reader :cve, :config, :vulenv_config, :attack_config

  def initialize(args)
    @cve = args[:cve]
    @vulenv_config = nil
    @attack_config = nil
    @config = YAML.load_file('./config.yml')
  end

  def select_test_case?
    vultest_configs = DB.get_vultest_configs(cve)

    if vultest_configs.empty?
      VultestUI.error('Cannot test vulnerability because the software doesn\'t have config file')
      return false
    end

    test_case_table = create_table(vultest_configs)
    msg = 'Select an id for testing vulnerability envrionment?'
    select_test_case_name = TTY::Prompt.new.enum_select(msg, test_case_table[:name_list])

    select_id = test_case_table[:index_info][select_test_case_name]

    @vulenv_config = YAML.load_file("#{config['vultest_db_path']}/#{vultest_configs[select_id.to_i - 1]['config_path']}")
    @attack_config = YAML.load_file("#{config['vultest_db_path']}/#{vultest_configs[select_id.to_i - 1]['module_path']}")
    true
  end

  private

  def create_table(configs)
    name_list = []
    table = []
    idx_info = {}

    configs.each_with_index do |config, idx|
      table.push([idx + 1, config['name']])
      idx_info[config['name']] = idx
      name_list << config['name']
    end

    puts('Vulnerability environment list')
    header = ['id', 'vulenv name']
    table = TTY::Table.new(header, table)
    table.render(:ascii).each_line do |line|
      puts line.chomp
    end

    { name_list: name_list, index_info: idx_info }
  end
end
