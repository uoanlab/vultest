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
require 'erb'
require 'fileutils'

require 'lib/ansible/roles/apr'
require 'lib/ansible/roles/apr_util'
require 'lib/ansible/roles/bash'
require 'lib/ansible/roles/httpd'
require 'lib/ansible/roles/orientdb'
require 'lib/ansible/roles/pcre'
require 'lib/ansible/roles/php'
require 'lib/ansible/roles/ruby'
require 'lib/ansible/roles/wordpress'
require 'lib/ansible/roles/wp_cli'

module Ansible
  module Roles
    module SourceInstall
      class << self
        def create(args)
          role_dir = args[:role_dir]
          software = args[:software]

          case software['name']
          when 'apr' then APR.create(role_dir, software)
          when 'apr-util' then APRUtil.create(role_dir, software)
          when 'bash' then Bash.create(role_dir, software)
          when 'httpd' then Httpd.create(role_dir, software)
          when 'orientdb' then OrientDB.create(role_dir, software)
          when 'pcre' then PCRE.create(role_dir, software)
          when 'php' then PHP.create(role_dir, software)
          when 'ruby' then Ruby.create(role_dir, software)
          when 'wordpress' then Wordpress.create(role_dir, software)
          when 'wp-cli' then WPCLI.create(role_dir, software)
          end
        end
      end
    end
  end
end
