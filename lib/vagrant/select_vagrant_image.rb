# Copyright [2020] [University of Aizu]
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
require 'fileutils'
require 'open3'
require 'tty-table'
require 'tty-prompt'

require 'lib/print'

module Vagrant
  class SelectVagrantImage
    def exec
      box_list = create_table

      select_box = TTY::Prompt.new.enum_select(
        'Select an id for testing vagrant image?',
        box_list.map { |b| "#{b[1]}:#{b[2]}" }
      )

      { box_name: select_box.split(':')[0], box_version: select_box.split(':')[1] }
    end

    private

    def create_table
      table = []

      stdout, _stderr, _status = Open3.capture3('vagrant box list')
      stdout = stdout.split("\n")

      stdout.each.with_index(1) do |box, idx|
        array = box.delete('(').delete(')').split(' ')

        table.push([idx, array[0], array[2]])
      end
      box_list = table.dup

      Print.stdout('Vagrant box list in your machine')
      header = ['id', 'box name', 'box version']
      table = TTY::Table.new(header, table)
      table.render(:ascii).each_line do |line|
        Print.stdout(line.chomp)
      end

      box_list
    end
  end
end
