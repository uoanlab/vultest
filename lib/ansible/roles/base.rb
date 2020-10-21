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

module Ansible
  module Roles
    class Base
      attr_reader :dir

      def initialize(args)
        @resource_path = args[:resource_path]
        @role_path = args[:role_path]
        @dir = args[:dir]

        @data = args[:data]
      end

      def create
        FileUtils.mkdir_p(@role_path)

        create_tasks
        create_vars
      end

      private

      def create_tasks
        FileUtils.mkdir_p("#{@role_path}/tasks")
        data = @data

        erb = ERB.new(
          ::File.read("#{@resource_path}/tasks/main.yml.erb"),
          trim_mode: 2
        )

        ::File.open("#{@role_path}/tasks/main.yml", 'w') do |f|
          f.puts(erb.result(binding))
        end
      end

      def create_vars
        FileUtils.mkdir_p("#{@role_path}/vars")

        data = @data
        erb = ERB.new(
          ::File.read("#{@resource_path}/vars/main.yml.erb"),
          trim_mode: 2
        )

        ::File.open("#{@role_path}/vars/main.yml", 'w') do |f|
          f.puts(erb.result(binding))
        end
      end
    end
  end
end
