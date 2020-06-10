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
require 'lib/ansible/role/content/software/apt'
require 'lib/ansible/role/content/software/yum'
require 'lib/ansible/role/content/software/gem'
require 'lib/ansible/role/content/software/source/bash'
require 'lib/ansible/role/content/software/source/ruby'
require 'lib/ansible/role/content/software/source/orientdb'
require 'lib/ansible/role/content/software/source/apache_httpd'
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
            when 'apt' then Content::Software::Apt.new(role_dir: role_dir, software: software)
            when 'yum' then Content::Software::Yum.new(role_dir: role_dir, software: software)
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
          when 'apt' then Content::Software::Apt.new(role_dir: role_dir, software: env_config['vul_software'])
          when 'yum' then Content::Software::Yum.new(role_dir: role_dir, software: env_config['vul_software'])
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

      def source_software_type(software)
        case software['name']
        when 'bash'
          Content::Software::Source::Bash.new(role_dir: role_dir, software: software)
        when 'ruby'
          Content::Software::Source::Ruby.new(role_dir: role_dir, software: software)
        when 'orientdb'
          Content::Software::Source::OrientDB.new(role_dir: role_dir, software: software)
        when 'apache-httpd'
          Content::Software::Source::ApacheHTTPd.new(role_dir: role_dir, software: software)
        end
      end
    end
  end
end
