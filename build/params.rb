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

require_relative './lib/software'
require_relative './lib/content'
require_relative '../ui'

module ConstructionParams
  include AssistContent
  include AssistSoftware

  private

  def local(role_dir)
    FileUtils.mkdir_p("#{role_dir}/metasploit")
    FileUtils.mkdir_p("#{role_dir}/metasploit/tasks")
    FileUtils.mkdir_p("#{role_dir}/metasploit/vars")
    FileUtils.mkdir_p("#{role_dir}/metasploit/files")
    FileUtils.cp_r(
      './build/ansible/roles/metasploit/tasks/main.yml',
      "#{role_dir}/metasploit/tasks/main.yml"
    )
    FileUtils.cp_r(
      './build/ansible/roles/metasploit/vars/main.yml',
      "#{role_dir}/metasploit/vars/main.yml"
    )
    FileUtils.cp_r(
      './build/ansible/roles/metasploit/files/database.yml',
      "#{role_dir}/metasploit/files/database.yml"
    )
  end

  def user(args)
    FileUtils.mkdir_p("#{args[:role_dir]}/user")
    FileUtils.mkdir_p("#{args[:role_dir]}/user/tasks")
    FileUtils.mkdir_p("#{args[:role_dir]}/user/vars")

    FileUtils.cp_r(
      './build/ansible/roles/user/tasks/main.yml',
      "#{args[:role_dir]}/user/tasks/main.yml"
    )

    File.open("#{args[:role_dir]}/user/vars/main.yml", 'w') do |vars_file|
      args[:users].each do |user|
        user ? vars_file.puts("user: #{user}") : vars_file.puts('user: test')
      end
    end
  end

  def related_software(args = {})
    args[:softwares].each do |software|
      method = software.key?('method') ? software['method'] : args[:default_method]
      select_method(software: software, role_dir: args[:role_dir], method: method)
    end
  end

  def vul_software(args = {})
    method = args[:vul_software].key?('method') ? args[:vul_software]['method'] : args[:default_method]
    select_method(software: args[:vul_software], role_dir: args[:role_dir], method: method)
  end

  def content(args = {})
    content_tasks(args)

    select_content_vars_dir = "#{args[:db]}/data/#{args[:content_info]}/vars"
    content_vars(args) if Dir.exist?(select_content_vars_dir)

    select_content_files_dir = "#{args[:db]}/data/#{args[:content_info]}/files"
    content_files(args) if Dir.exist?(select_content_files_dir)
  end

  def prepare(args)
    VultestUI.warring('Following execute command')
    puts("  [1] cd #{args[:env_dir]}")
    puts('  [2] vagrant ssh')
    args[:prepare_msg].each.with_index(3) { |msg, i| puts "  [#{i}] #{msg}" }
  end
end
