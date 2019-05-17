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

require_relative '../../utility'

module Ansible

  def create(vulconfig_file, vulenv_dir)
    vulconfig = YAML.load_file(vulconfig_file)
    config = YAML.load_file('./config.yml')

    # Create ansible directory
    ansible_dir = {}
    ansible_dir['base'] = "#{vulenv_dir}/ansible"
    ansible_dir['hosts'] = "#{ansible_dir['base']}/hosts"
    ansible_dir['playbook'] = "#{ansible_dir['base']}/playbook"
    ansible_dir['roles'] =  "#{ansible_dir['base']}/roles"

    FileUtils.mkdir_p("#{ansible_dir['base']}")
    FileUtils.mkdir_p("#{ansible_dir['hosts']}")
    FileUtils.mkdir_p("#{ansible_dir['playbook']}")
    FileUtils.mkdir_p("#{ansible_dir['roles']}")

    # Create anslbe tasks
    FileUtils.cp_r("./build/ansible/ansible.cfg", "#{ansible_dir['base']}/ansible.cfg")
    FileUtils.cp_r("./build/ansible/hosts/hosts.yml", "#{ansible_dir['hosts']}/hosts.yml")

    if vulconfig['attack_vector'] == 'local'
      FileUtils.mkdir_p("#{ansible_dir['roles']}/metasploit")
      FileUtils.mkdir_p("#{ansible_dir['roles']}/metasploit/tasks")
      FileUtils.mkdir_p("#{ansible_dir['roles']}/metasploit/vars")
      FileUtils.mkdir_p("#{ansible_dir['roles']}/metasploit/files")

      FileUtils.cp_r("./build/ansible/roles/metasploit/tasks/main.yml", "#{ansible_dir['roles']}/metasploit/tasks/main.yml")
      FileUtils.cp_r("./build/ansible/roles/metasploit/vars/main.yml", "#{ansible_dir['roles']}/metasploit/vars/main.yml")
      FileUtils.cp_r("./build/ansible/roles/metasploit/files/database.yml", "#{ansible_dir['roles']}/metasploit/files/database.yml")
    end

    if vulconfig['construction'].key?('user')
      FileUtils.mkdir_p("#{ansible_dir['roles']}/user")
      FileUtils.mkdir_p("#{ansible_dir['roles']}/user/tasks")
      FileUtils.mkdir_p("#{ansible_dir['roles']}/user/vars")

      FileUtils.cp_r("./build/ansible/roles/user/tasks/main.yml", "#{ansible_dir['roles']}/user/tasks/main.yml")

      File.open("#{ansible_dir['roles']}/user/vars/main.yml", "w") do |vars_file|
        vulconfig['construction']['user'].each do |user|
          user ? vars_file.puts("user: #{user}") : vars_file.puts('user: test')
        end
      end
    end

    # related software
    if vulconfig['construction'].key?('related_software')
      vulconfig['construction']['related_software'].each do |software|
        case software['method']
        when 'apt'
          self.role_apt(ansible_dir['roles'], software)
        when 'yum'
          self.role_yum(ansible_dir['roles'], software)
        when'gem'
          self.role_gem(ansible_dir['roles'], software)
        when 'source'
          self.role_source(ansible_dir['roles'], software)
        end
      end
    end

    # vulnerable software
    if vulconfig['construction'].key?('vul_software')
      case vulconfig['construction']['vul_software']['method']
        when 'apt'
          self.role_apt(ansible_dir['roles'], vulconfig['construction']['vul_software'])
        when 'yum'
          self.role_yum(ansible_dir['roles'], vulconfig['construction']['vul_software'])
        when'gem'
          self.role_gem(ansible_dir['roles'], vulconfig['construction']['vul_software'])
        when 'source'
          self.role_source(ansible_dir['roles'], vulconfig['construction']['vul_software'])
        end
    end

    # content
    if vulconfig['construction'].key?('content')
      # tasks directory
      FileUtils.mkdir_p("#{ansible_dir['roles']}/#{vulconfig['cve']}/tasks")
      FileUtils.cp_r("#{config['vultest_db_path']}/data/#{vulconfig['construction']['content']}/tasks/main.yml", "#{ansible_dir['roles']}/#{vulconfig['cve']}/tasks/main.yml")

      # vars directory
      if Dir.exist?("#{config['vultest_db_path']}/data/#{vulconfig['construction']['content']}/vars")
        FileUtils.mkdir_p("#{ansible_dir['roles']}/#{vulconfig['cve']}/tasks/vars")
        FileUtils.cp_r("#{config['vultest_db_path']}/data/#{vulconfig['construction']['content']}/vars/main.yml", "#{ansible_dir['roles']}/#{vulconfig['cve']}/vars/main.yml")
      end

      # files directory
      if Dir.exist?("#{config['vultest_db_path']}/data/#{vulconfig['construction']['content']}/files")
        FileUtils.mkdir_p("#{ansible_dir['roles']}/#{vulconfig['cve']}/files")
        Dir.glob("#{config['vultest_db_path']}/data/#{vulconfig['construction']['content']}/files/*") do |path|
          file_or_dir = path.split('/')
          FileUtils.cp_r("#{config['vultest_db_path']}/data/#{vulconfig['construction']['content']}/files/#{file_or_dir[file_or_dir.size - 1]}", 
                         "#{ansible_dir['roles']}/#{vulconfig['cve']}/files/#{file_or_dir[file_or_dir.size - 1]}")
        end
      end
    end

    # Create playbook
    File.open("#{ansible_dir['playbook']}/main.yml", "w") do |playbook_file|
      playbook_file.puts("---\n- hosts: vagrant\n  connection: local \n  become: yes \n  roles: ")

      # Create user
      playbook_file.puts('    - ../roles/user') if vulconfig['construction'].key?('user')

      # add roles in playbook
      if vulconfig['construction'].key?('related_software')
        vulconfig['construction']['related_software'].each do |software|
          playbook_file.puts("    - ../roles/#{software['name']} ")
        end
      end

      if vulconfig['construction'].key?('vul_software')
        playbook_file.puts("    - ../roles/#{vulconfig['construction']['vul_software']['name']} ") 
      end

      playbook_file.puts("    - ../roles/#{vulconfig['cve']} ") if vulconfig['construction'].key?('content')
      playbook_file.puts("    - ../roles/metasploit") if vulconfig['attack_vector'] == 'local'
    end

  end

  def role_apt(roles_dir, software)
    # tasks
    FileUtils.mkdir_p("#{roles_dir}/#{software['name']}/tasks")
    software['name'] =~ /^linux-image/ ? FileUtils.cp_r("./build/ansible/roles/os/ubuntu/kernel/tasks/main.yml", "#{roles_dir}/#{software['name']}/tasks/main.yml") : FileUtils.cp_r("./build/ansible/roles/apt/tasks/main.yml", "#{roles_dir}/#{software['name']}/tasks/main.yml")

    # vars
    FileUtils.mkdir_p("#{roles_dir}/#{software['name']}/vars")
    File.open("#{roles_dir}/#{software['name']}/vars/main.yml", "w") do |vars_file|
      vars_file.puts("---")
      vars_file.puts("name_and_version: #{software['name']}=#{software['version']}")
    end
  end

  def role_gem(roles_dir, software)
    # tasks
    FileUtils.mkdir_p("#{roles_dir}/#{software['name']}/tasks")
    FileUtils.cp_r("./build/ansible/roles/gem/tasks/main.yml", "#{roles_dir}/#{software['name']}/tasks/main.yml")

    # vars
    FileUtils.mkdir_p("#{roles_dir}/#{software['name']}/vars")
    File.open("#{roles_dir}/#{software['name']}/vars/main.yml", "w") do |vars_file|
      vars_file.puts("---")

      vars_file.puts("name: #{software['name']}")
      vars_file.puts("version: #{software['version']}")
      software['user'] ? vars_file.puts("user: #{software['user']}\nuser_dir: /home/#{software['user']}") : vars_file.puts("user: test\nvars_file.puts('user_dir: /home/test")
    end
  end

  def role_source(roles_dir, software)
    # tasks
    FileUtils.mkdir_p("#{roles_dir}/#{software['name']}/tasks")
    FileUtils.cp_r("./build/ansible/roles/source/#{software['name']}/tasks/main.yml", "#{roles_dir}/#{software['name']}/tasks/main.yml")

    # vars
    FileUtils.mkdir_p("#{roles_dir}/#{software['name']}/vars")
    File.open("#{roles_dir}/#{software['name']}/vars/main.yml", "w") do |vars_file|
      vars_file.puts("---")

      vars_file.puts("version: #{software['version']}") if software.key?('version')
      vars_file.puts("configure_command: #{software['configure_command']}") if software.key?('configure_command')

      if software.key?('src_dir')
        software['src_dir'] ? vars_file.puts("src_dir: #{software['src_dir']}") : vars_file.puts("src_dir: /usr/local/src") 
      end

      if software.key?('user')
        software['user'] ? vars_file.puts("user: #{software['user']}\nuser_dir: /home/#{software['user']}") : vars_file.puts("user: test\nvars_file.puts('user_dir: /home/test")
      end
    end
  end

  def role_yum(roles_dir, software)
    # tasks 
    FileUtils.mkdir_p("#{roles_dir}/#{software['name']}/tasks")
    FileUtils.cp_r("./build/ansible/roles/yum/tasks/main.yml", "#{roles_dir}/#{software['name']}/tasks/main.yml")

    # vars
    FileUtils.mkdir_p("#{roles_dir}/#{software['name']}/vars")
    File.open("#{roles_dir}/#{software['name']}/vars/main.yml", "w") do |vars_file|
      vars_file.puts("---")
      vars_file.puts("name_and_version: #{software['name']}-#{software['version']}")
    end
  end

  module_function :create
  module_function :role_apt
  module_function :role_gem
  module_function :role_source
  module_function :role_yum

end

