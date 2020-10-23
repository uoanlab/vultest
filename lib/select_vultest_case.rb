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

class SelectVultestCase
  CONFIG_VERSION = 1.0

  def initialize(args)
    @cve = args[:cve]
    @test_cases = []
  end

  def test_case_empty?
    @test_cases = DB.get_vultest_configs(@cve)

    return false unless @test_cases.empty?

    Print.error('Cannot test vulnerability because the software doesn\'t have config file')
    true
  end

  def exec
    table = create_table
    select_test_case = TTY::Prompt.new.enum_select(
      'Select an id for testing vulnerability envrionment?',
      table[:name_list]
    )

    id = table[:index_info][select_test_case] - 1

    test_case = DataObject::TestCase.new(
      vulenv_config_file: @test_cases[id.to_i]['config_path'],
      attack_config_file: @test_cases[id.to_i]['module_path']
    )

    return nil unless check_config_version?(test_case.version)

    test_case
  end

  private

  def create_table
    name_list = []
    table = []
    idx_info = {}

    @test_cases.each.with_index(1) do |config, idx|
      table.push([idx, config['name']])
      idx_info[config['name']] = idx
      name_list << config['name']
    end

    Print.stdout('Vulnerability environment list')
    header = ['id', 'vulenv name']
    table = TTY::Table.new(header, table)
    table.render(:ascii).each_line do |line|
      Print.stdout(line.chomp)
    end

    { name_list: name_list, index_info: idx_info }
  end

  def check_config_version?(version)
    if version.to_i > CONFIG_VERSION || version.to_i < CONFIG_VERSION
      Print.error("Configfile is #{version}(support: #{CONFIG_VERSION})")
      return false
    end

    true
  end
end
