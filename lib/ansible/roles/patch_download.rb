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
require 'yaml'

module Ansible
  module Roles
    class PatchDownload
      attr_reader :path

      def initialize(args)
        @role_dir = args[:role_dir]

        @software = {
          name: args[:software]['name'],
          version: args[:software]['version'],
          src_dir: args[:software]['src_dir']
        }

        @patch_version = args[:patch_version]

        metadata = YAML.load_file('./metadata.yml')
        @url = metadata['softwares'][@software[:name]]['patch']['url']
        @download_file = metadata['softwares'][@software[:name]]['patch']['download_file']
      end

      def create
        @patch_version =
          case @patch_version.to_s.length
          when 1 then "00#{@patch_version}"
          when 2 then "0#{@patch_version}"
          else @patch_version.to_s
          end

        @url.sub!(
          /{{ core_version }}/,
          "#{@software[:version].to_s.split('.')[0]}.#{@software[:version].to_s.split('.')[1]}"
        )
        @url.sub!(
          /{{ core_version }}/,
          "#{@software[:version].to_s.split('.')[0]}#{@software[:version].to_s.split('.')[1]}"
        )
        @url.gsub!(/{{ patch_version }}/, @patch_version.to_s)

        FileUtils.mkdir_p("#{@role_dir}/#{@software[:name]}.patch.#{@patch_version}.download")

        create_tasks
        create_vars

        @path = "#{@software[:name]}.patch.#{@patch_version}.download"
      end

      private

      def create_tasks
        FileUtils.mkdir_p("#{@role_dir}/#{@software[:name]}.patch.#{@patch_version}.download")

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/patch/download/tasks",
          "#{@role_dir}/#{@software[:name]}.patch.#{@patch_version}.download"
        )
      end

      def create_vars
        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/patch/download/vars",
          "#{@role_dir}/#{@software[:name]}.patch.#{@patch_version}.download"
        )

        path = "#{@role_dir}/#{@software[:name]}.patch.#{@patch_version}.download/vars/main.yml"
        File.open(path, 'a') do |f|
          f.puts("src_dir: #{@software[:src_dir]}")
          f.puts("url: #{@url}")
        end
      end
    end
  end
end