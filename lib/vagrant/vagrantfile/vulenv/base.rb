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

require 'bundler/setup'
require 'fileutils'
require 'open3'
require 'tty-table'
require 'tty-prompt'

require 'lib/vagrant/vagrantfile/base'

module Vagrant
  module Vagrantfile
    module Vulenv
      class Base < ::Vagrant::Vagrantfile::Base
        attr_reader :os_name, :os_version

        def initialize(args)
          super(env_dir: args[:env_dir])
          @os_name = args[:os_name]
          @os_version = args[:os_version]
        end

        private

        def create_table_of_vagrant_img
          table_index = 1
          table = []

          stdout, _stderr, _status = Open3.capture3('vagrant box list')
          stdout = stdout.split("\n")

          stdout.each do |box|
            array = box.delete('(').delete(')').split(' ')

            table.push([table_index, array[0], array[2]])
            table_index += 1
          end
          box_list = table.dup

          puts('Vagrant box list in your machine')
          header = ['id', 'box name', 'box version']
          table = TTY::Table.new(header, table)
          table.render(:ascii).each_line do |line|
            puts line.chomp
          end

          box_list
        end

        def select_vagrant_image_in_local
          box_list = create_table_of_vagrant_img
          list = []
          box_list.each { |b| list << "#{b[1]}:#{b[2]}" }

          message = 'Select an id for testing vagrant image?'
          select_box = TTY::Prompt.new.enum_select(message, list)

          { box_name: select_box.split(':')[0], box_version: select_box.split(':')[1] }
        end
      end
    end
  end
end
