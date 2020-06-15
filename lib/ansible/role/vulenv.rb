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

require 'lib/ansible/role/content/metasploit'
require 'lib/ansible/role/content/user'

require 'lib/ansible/role/content/software/apt/package'

require 'lib/ansible/role/content/software/yum/package'
require 'lib/ansible/role/content/software/yum/mysql'

require 'lib/ansible/role/content/software/gem'

require 'lib/ansible/role/content/software/source/apr'
require 'lib/ansible/role/content/software/source/apr_util'
require 'lib/ansible/role/content/software/source/bash'
require 'lib/ansible/role/content/software/source/httpd'
require 'lib/ansible/role/content/software/source/orientdb'
require 'lib/ansible/role/content/software/source/pcre'
require 'lib/ansible/role/content/software/source/php'
require 'lib/ansible/role/content/software/source/ruby'
require 'lib/ansible/role/content/software/source/wordpress'
require 'lib/ansible/role/content/software/source/wp_cli'

require 'lib/ansible/role/content/content'
require 'lib/ansible/role/content/service'

module Ansible
  module Role
    class Vulenv
      attr_reader :role_dir, :db_path, :env_config, :cve, :attack_vector

      def initialize(args)
        @role_dir = args[:role_dir]
        @db_path = args[:db_path]
        @env_config = args[:env_config]
        @cve = args[:cve]
        @attack_vector = args[:attack_vector]
      end

      def create
        if attack_vector == 'local'
          role = Content::Metasploit.new(
            role_dir: role_dir,
            os_name: env_config['os']['name'],
            os_version: env_config['os']['version'],
            attack_host: '192.168.177.177'
          )
          role.create
        end

        user_parameter

        default_method = env_config['os'].fetch('default_method', nil)
        related_software_parameter(default_method)
        vul_software_parameter(default_method)

        content_parameter
        services_parameter
      end

      private

      def user_parameter
        return unless env_config.key?('user')

        role = Content::User.new(role_dir: role_dir, users: env_config['user'])
        role.create
      end

      def related_software_parameter(default_method)
        return unless env_config.key?('related_software')

        env_config['related_software'].each do |software|
          method = software.fetch('method', default_method)
          role =
            case method
            when 'apt' then apt_software_type(software)
            when 'yum' then yum_software_type(software)
            when 'gem' then Content::Software::Gem.new(role_dir: role_dir, software: software)
            when 'source' then source_software_type(software)
            end
          role.create
        end
      end

      def vul_software_parameter(default_method)
        return unless env_config.key?('vul_software')

        method = env_config['vul_software'].fetch('method', default_method)
        role =
          case method
          when 'apt' then apt_software_type(env_config['vul_software'])
          when 'yum' then yum_software_type(env_config['vul_software'])
          when 'gem' then Content::Software::Gem.new(role_dir: role_dir, software: env_config['vul_software'])
          when 'source' then source_software_type(env_config['vul_software'])
          end
        role.create
      end

      def content_parameter
        return unless env_config.key?('content')

        role = Content::Content.new(role_dir: role_dir, db_path: db_path, cve: cve, content: env_config['content'])
        role.create
      end

      def services_parameter
        return unless env_config.key?('services')

        env_config['services'].each do |service|
          role = Content::Service.new(role_dir: role_dir, service: service)
          role.create
        end
      end

      def apt_software_type(software)
        Content::Software::Apt::Package.new(role_dir: role_dir, software: software)
      end

      def yum_software_type(software)
        case software['name']
        when 'mysql' then Content::Software::Yum::MySQL.new(role_dir: role_dir, software: software, os_version: env_config['os']['version'])
        else Content::Software::Yum::Package.new(role_dir: role_dir, software: software)
        end
      end

      def source_software_type(software)
        case software['name']
        when 'apr' then Content::Software::Source::APR.new(role_dir: role_dir, software: software)
        when 'apr-util' then Content::Software::Source::APRUtil.new(role_dir: role_dir, software: software)
        when 'bash' then Content::Software::Source::Bash.new(role_dir: role_dir, software: software)
        when 'httpd' then Content::Software::Source::Httpd.new(role_dir: role_dir, software: software)
        when 'orientdb' then Content::Software::Source::OrientDB.new(role_dir: role_dir, software: software)
        when 'pcre' then Content::Software::Source::PCRE.new(role_dir: role_dir, software: software)
        when 'php' then Content::Software::Source::PHP.new(role_dir: role_dir, software: software)
        when 'ruby' then Content::Software::Source::Ruby.new(role_dir: role_dir, software: software)
        when 'wordpress' then Content::Software::Source::Wordpress.new(role_dir: role_dir, software: software)
        when 'wp-cli' then Content::Software::Source::WPCLI.new(role_dir: role_dir, software: software)
        end
      end
    end
  end
end
