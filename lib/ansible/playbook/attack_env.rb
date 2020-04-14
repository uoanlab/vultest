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

module Ansible
  module Playbook
    class AttackEnv
      attr_reader :playbook_dir

      def initialize(args)
        @playbook_dir = args[:playbook_dir]
      end

      def create
        content = "---\n"
        content << "- hosts: vagrant\n"
        content << "  connection: local\n"
        content << "  become: yes \n"
        content << "  roles:\n"
        content << "    - ../roles/metasploit\n"

        File.open("#{playbook_dir}/main.yml", 'w') { |file| file.puts(content) }
      end
    end
  end
end
