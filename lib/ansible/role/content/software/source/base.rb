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

require 'lib/ansible/role/content/software/base'

module Ansible
  module Role
    module Content
      module Software
        module Source
          class Base < Software::Base
            private

            def configure
              cmd = 'configure_command: ./configure'
              software.fetch('configure_options', {}).each do |k, v|
                cmd << if v.empty? then " --#{k}"
                       else " --#{k}=#{v}"
                       end
              end
              cmd
            end

            def src_dir
              'src_dir: ' << software.fetch('src_dir', '/usr/local/src')
            end

            def software_path(default_path)
              path = software.fetch('configure_options', nil)
              'software_path: ' << if path.nil? || !path.key?('prefix') then default_path
                                   elsif path.key?('prefix') then path['prefix']
                                   end
            end
          end
        end
      end
    end
  end
end
