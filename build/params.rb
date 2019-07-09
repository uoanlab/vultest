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

  def local(ansible_dir)
    FileUtils.mkdir_p("#{ansible_dir[:roles]}/metasploit")
    FileUtils.mkdir_p("#{ansible_dir[:roles]}/metasploit/tasks")
    FileUtils.mkdir_p("#{ansible_dir[:roles]}/metasploit/vars")
    FileUtils.mkdir_p("#{ansible_dir[:roles]}/metasploit/files")
    FileUtils.cp_r(
      './build/ansible/roles/metasploit/tasks/main.yml',
      "#{ansible_dir[:roles]}/metasploit/tasks/main.yml"
    )
    FileUtils.cp_r(
      './build/ansible/roles/metasploit/vars/main.yml',
      "#{ansible_dir[:roles]}/metasploit/vars/main.yml"
    )
    FileUtils.cp_r(
      './build/ansible/roles/metasploit/files/database.yml',
      "#{ansible_dir[:roles]}/metasploit/files/database.yml"
    )
  end

  def user(env_config, ansible_dir)
    FileUtils.mkdir_p("#{ansible_dir[:roles]}/user")
    FileUtils.mkdir_p("#{ansible_dir[:roles]}/user/tasks")
    FileUtils.mkdir_p("#{ansible_dir[:roles]}/user/vars")

    FileUtils.cp_r(
      './build/ansible/roles/user/tasks/main.yml',
      "#{ansible_dir[:roles]}/user/tasks/main.yml"
    )

    File.open("#{ansible_dir[:roles]}/user/vars/main.yml", 'w') do |vars_file|
      env_config['construction']['user'].each do |user|
        user ? vars_file.puts("user: #{user}") : vars_file.puts('user: test')
      end
    end
  end

  def related_software(env_config, ansible_dir)
    env_config['construction']['related_software'].each do |software|
      method =
        if software.key?('method')
          software['method']
        else
          env_config['construction']['os']['default_method']
        end
      select_method(software, ansible_dir[:roles], method)
    end
  end

  def vul_software(env_config, ansible_dir)
    method =
      if env_config['construction']['vul_software'].key?('method')
        env_config['construction']['vul_software']['method']
      else
        env_config['construction']['os']['default_method']
      end
    select_method(env_config['construction']['vul_software'], ansible_dir[:roles], method)
  end

  def content(config, env_config, ansible_dir)
    content_tasks(config['vultest_db_path'], env_config, ansible_dir[:roles])

    select_content_vars_dir = "#{config['vultest_db_path']}/data/#{env_config['construction']['content']}/vars"
    content_vars(config['vultest_db_path'], env_config, ansible_dir[:roles]) if Dir.exist?(select_content_vars_dir)

    select_content_files_dir = "#{config['vultest_db_path']}/data/#{env_config['construction']['content']}/files"
    content_files(config['vultest_db_path'], env_config, ansible_dir[:roles]) if Dir.exist?(select_content_files_dir)
  end

  def prepare(env_dir, env_config)
    VultestUI.print_vultest_message('caution', 'Following execute command')
    puts("  [1] cd #{env_dir}")
    puts('  [2] vagrant ssh')
    env_config['construction']['prepare']['msg'].each.with_index(3) { |msg, i| puts "  [#{i}] #{msg}" }

    VultestUI.print_vultest_message('caution', 'Press ENTER when you prepare vulnerable environment.')
    gets
  end
end
