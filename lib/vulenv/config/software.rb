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

module Software
  private

  def select_method(args = {})
    case args[:method]
    when 'apt' then method_apt(name: args[:software]['name'], version: args[:software]['version'], role_dir: args[:role_dir])
    when 'yum' then method_yum(name: args[:software]['name'], version: args[:software]['version'], role_dir: args[:role_dir])
    when 'gem' then method_gem(software: args[:software], role_dir: args[:role_dir])
    when 'source' then method_source(software: args[:software], role_dir: args[:role_dir])
    end
  end

  def method_apt(args = {})
    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:name]}/tasks")
    FileUtils.cp_r('./lib/vulenv/tools/data/ansible/roles/apt/tasks/main.yml', "#{args[:role_dir]}/#{args[:name]}/tasks/main.yml")

    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:name]}/vars")
    File.open("#{args[:role_dir]}/#{args[:name]}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      vars_file.puts("name_and_version: #{args[:name]}=#{args[:version]}")
    end
  end

  def method_yum(args = {})
    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:name]}/tasks")
    FileUtils.cp_r('./lib/vulenv/tools/data/ansible/roles/yum/tasks/main.yml', "#{args[:role_dir]}/#{args[:name]}/tasks/main.yml")

    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:name]}/vars")
    File.open("#{args[:role_dir]}/#{args[:name]}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      vars_file.puts("name_and_version: #{args[:name]}-#{args[:version]}")
    end
  end

  def method_gem(args = {})
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

  def method_source(args = {})
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
    version[2].to_i.times do |index|
      index += 1
      if index.to_i < 10
        vars_file.puts("   - {name: patch-#{index}, version: bash#{version[0]}#{version[1]}-00#{index}}")
      elsif (index.to_i >= 10) && (index.to_i < 100)
        vars_file.puts("   - {name: patch-#{index}, version: bash#{version[0]}#{version[1]}-0#{index}}")
      else
        vars_file.puts("   - {name: patch-#{index}, version: bash#{version[0]}#{version[1]}-#{index}}")
      end
    end
  end

  def option_configure_command(vars_file, software)
    if software.key?('configure_command')
      vars_file.puts("configure_command: #{software['configure_command']}")
    else
      vars_file.puts('configure_command: ./configure')
    end
  end

  def option_src_dir(vars_file, software)
    if software.key?('src_dir')
      vars_file.puts("src_dir: #{software['src_dir']}")
    else
      vars_file.puts('src_dir: /usr/local/src')
    end
  end

  def option_user(vars_file, software)
    if software.key?('user') && !software['user'].nil?
      vars_file.puts("user: #{software['user']}\nuser_dir: /home/#{software['user']}")
    else
      vars_file.puts("user: test\nuser_dir: /home/test")
    end
  end
end
