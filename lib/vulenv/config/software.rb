# Copyright [2019] [University of Aizu]
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
module Software
  private

  def vul_software(args)
    method = args[:vul_software].key?('method') ? args[:vul_software]['method'] : args[:default_method]
    select_method(software: args[:vul_software], role_dir: args[:role_dir], method: method)
  end

  def related_software(args)
    args[:softwares].each do |software|
      method = software.key?('method') ? software['method'] : args[:default_method]
      select_method(software: software, role_dir: args[:role_dir], method: method)
    end
  end

  def select_method(args)
    case args[:method]
    when 'apt' then method_apt(name: args[:software]['name'], version: args[:software]['version'], role_dir: args[:role_dir])
    when 'yum' then method_yum(name: args[:software]['name'], version: args[:software]['version'], role_dir: args[:role_dir])
    when 'gem' then method_gem(software: args[:software], role_dir: args[:role_dir])
    when 'source' then method_source(software: args[:software], role_dir: args[:role_dir])
    end
  end

  def method_apt(args)
    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:name]}/tasks")
    FileUtils.cp_r('./lib/vulenv/tools/data/ansible/roles/apt/tasks/main.yml', "#{args[:role_dir]}/#{args[:name]}/tasks/main.yml")

    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:name]}/vars")
    File.open("#{args[:role_dir]}/#{args[:name]}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      vars_file.puts("name_and_version: #{args[:name]}=#{args[:version]}")
    end
  end

  def method_yum(args)
    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:name]}/tasks")
    FileUtils.cp_r('./lib/vulenv/tools/data/ansible/roles/yum/tasks/main.yml', "#{args[:role_dir]}/#{args[:name]}/tasks/main.yml")

    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:name]}/vars")
    File.open("#{args[:role_dir]}/#{args[:name]}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      vars_file.puts("name_and_version: #{args[:name]}-#{args[:version]}")
    end
  end

  def method_gem(args)
    software_name = args[:software]['name']
    software_version = args[:software]['version']

    FileUtils.mkdir_p("#{args[:role_dir]}/#{software_name}/tasks")
    FileUtils.cp_r(
      './lib/vulenv/tools/data/ansible/roles/gem/tasks/main.yml',
      "#{args[:role_dir]}/#{software_name}/tasks/main.yml"
    )

    FileUtils.mkdir_p("#{args[:role_dir]}/#{software_name}/vars")
    File.open("#{args[:role_dir]}/#{software_name}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      vars_file.puts("name: #{software_name}")
      vars_file.puts("version: #{software_version}")
      option_user(vars_file, args[:software])
    end
  end

  def method_source(args)
    software_name = args[:software]['name']
    software_version = args[:software]['version']

    FileUtils.mkdir_p("#{args[:role_dir]}/#{software_name}/tasks")
    FileUtils.cp_r(
      "./lib/vulenv/tools/data/ansible/roles/source/#{software_name}/tasks/main.yml",
      "#{args[:role_dir]}/#{software_name}/tasks/main.yml"
    )

    FileUtils.mkdir_p("#{args[:role_dir]}/#{software_name}/vars")
    File.open("#{args[:role_dir]}/#{software_name}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      software_name == 'bash' ? source_bash(vars_file, software_version) : vars_file.puts("version: #{software_version}")
      option_configure_command(vars_file, args[:software])
      option_src_dir(vars_file, args[:software])
      option_user(vars_file, args[:software])
    end
  end

  def source_bash(vars_file, version)
    version = version.split('.')
    vars_file.puts("version: #{version[0] + '.' + version[1]}")
    vars_file.puts('patches:')
    version[2].to_i.times do |idx|
      idx += 1
      input = "   - {name: patch-#{idx}, version: bash#{version[0]}#{version[1]}-"
      input += if idx.to_i < 10 then '00'
               elsif (idx.to_i >= 10) && (idx.to_i < 100) then '0'
               end
      input += "#{idx}}"
      vars_file.puts(input)
    end
  end

  def option_configure_command(vars_file, software)
    input = 'configure_command: '
    input += software.key?('configure_command') ? software['configure_command'] : './configure'
    vars_file.puts(input)
  end

  def option_src_dir(vars_file, software)
    input = 'src_dir: '
    input += software.key?('src_dir') ? software['src_dir'] : '/usr/local/src'
    vars_file.puts(input)
  end

  def option_user(vars_file, software)
    input = if software.key?('user') && !software['user'].nil? then "user: #{software['user']}\nuser_dir: /home/#{software['user']}"
            else "user: test\nuser_dir: /home/test"
            end

    vars_file.puts(input)
  end
end
