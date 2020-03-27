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

require './lib/vulenv/tools/ansible/roles/software_role'

class SourceRole < SoftwareRole
  def create
    FileUtils.mkdir_p("#{role_dir}/#{software['name']}/tasks")
    FileUtils.cp_r(
      "./data/ansible/roles/source/#{software['name']}/tasks/main.yml",
      "#{role_dir}/#{software['name']}/tasks/main.yml"
    )

    FileUtils.mkdir_p("#{role_dir}/#{software['name']}/vars")
    File.open("#{role_dir}/#{software['name']}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      software_version = software['name'] == 'bash' ? source_bash : "version: #{software['version']}"
      vars_file.puts(software_version)
      vars_file.puts(option_configure_command)
      vars_file.puts(option_src_dir)
      vars_file.puts(option_user)
    end
  end

  private

  def source_bash
    version = software['version'].split('.')
    vars = "version: #{version[0] + '.' + version[1]}\n"
    vars << "patches:\n"
    version[2].to_i.times do |idx|
      idx += 1
      vars << "   - {name: patch-#{idx}, version: bash#{version[0]}#{version[1]}-"
      vars << if idx.to_i < 10 then '00'
              elsif (idx.to_i >= 10) && (idx.to_i < 100) then '0'
              end
      vars << "#{idx}}\n"
    end
    vars
  end
end
