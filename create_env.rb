require 'fileutils'
require 'yaml'

class CreateEnv

  def initialize(vulconfig_file, cnt)
    @vultest_dir = "./test/vulenv_#{cnt}"
    FileUtils.mkdir_p("#{@vultest_dir}")

    @vulconfig = YAML.load_file("#{vulconfig_file}")
  end

  def create_vagrantfile
    vagrantfile_dir = "./build/vagrant/#{@vulconfig['os']['name']}/#{@vulconfig['os']['version']}/Vagrantfile"
    FileUtils.cp_r("#{vagrantfile_dir}", "#{@vultest_dir}/Vagrantfile")
  end

  def create_ansible_dir
    @vultest_ansible_dir = "#{@vultest_dir}/ansible"
    @vultest_ansible_hosts_config_dir = "#{@vultest_dir}/ansible/hosts"
    @vultest_ansible_playbook_dir = "#{@vultest_dir}/ansible/playbook"
    @vultest_ansible_roles_dir = "#{@vultest_dir}/ansible/roles"

    FileUtils.mkdir_p("#{@vultest_ansible_dir}")
    FileUtils.mkdir_p("#{@vultest_ansible_hosts_config_dir}")
    FileUtils.mkdir_p("#{@vultest_ansible_playbook_dir}")
    FileUtils.mkdir_p("#{@vultest_ansible_roles_dir}")
  end

  def create_ansible_config
    ansible_config_file = "./build/ansible/ansible.cfg"
    FileUtils.cp_r("#{ansible_config_file}", "#{@vultest_ansible_dir}/ansible.cfg")
  end

  def create_ansible_hosts
    ansible_hosts_file = "./build/ansible/hosts/hosts.yml"
    FileUtils.cp_r("#{ansible_hosts_file}", "#{@vultest_ansible_hosts_config_dir}/hosts.yml")
  end

  def create_ansible_role

    if @vulconfig['attack_vector'] == 'local'
      FileUtils.mkdir_p("#{@vultest_ansible_roles_dir}/metasploit")
      FileUtils.mkdir_p("#{@vultest_ansible_roles_dir}/metasploit/tasks")
      FileUtils.mkdir_p("#{@vultest_ansible_roles_dir}/metasploit/vars")
      FileUtils.mkdir_p("#{@vultest_ansible_roles_dir}/metasploit/files")

      ansible_role_metasploit_dir = "./build/ansible/roles/metasploit"
      FileUtils.cp_r("#{ansible_role_metasploit_dir}/tasks/main.yml", "#{@vultest_ansible_roles_dir}/metasploit/tasks/main.yml")
      FileUtils.cp_r("#{ansible_role_metasploit_dir}/vars/main.yml", "#{@vultest_ansible_roles_dir}/metasploit/vars/main.yml")
      FileUtils.cp_r("#{ansible_role_metasploit_dir}/files/database.yml", "#{@vultest_ansible_roles_dir}/metasploit/files/database.yml")
    end

    return unless @vulconfig.key?('software')

    softwares = @vulconfig['software']
    softwares.each do |software|
      vultest_ansible_role_software_dir = "#{@vultest_ansible_roles_dir}/#{software['name']}"

      # create tasks dir
      FileUtils.mkdir_p("#{vultest_ansible_role_software_dir}/tasks")
      if software['os_depend']
        if software.key?('affect_kernel')
          ansible_role_dir = "./build/ansible/roles/os/#{@vulconfig['os']['name']}/#{software['name']}"
        elsif @vulconfig['os']['name'] == 'ubuntu'
          ansible_role_dir = "./build/ansible/roles/os/ubuntu/apt"
        elsif @vulconfig['os']['name'] == 'centos'
          ansible_role_dir = "./build/ansible/roles/os/centos/yum"
        end
      else
        ansible_role_dir = "./build/ansible/roles/#{software['name']}"
      end
      FileUtils.cp_r("#{ansible_role_dir}/tasks/main.yml", "#{vultest_ansible_role_software_dir}/tasks/main.yml")

      # create vars dir
      FileUtils.mkdir_p("#{vultest_ansible_role_software_dir}/vars")
      File.open("#{vultest_ansible_role_software_dir}/vars/main.yml", "w") do |vars_file|
        vars_file.puts("---")
        if software['os_depend'] && !software.key?('affect_kernel')
          if software.key?('version')
            vars_file.puts("name_and_version: #{software['name']}=#{software['version']}")
          else
            vars_file.puts("name_and_version: #{software['name']}")
          end
        else
          vars_file.puts("#{software['name']}: #{software['version']}")
          vars_file.puts("configure_command: #{software['configure_command']}") if software.key?('configure_command')
        end

        if software.key?('src_dir')
          unless software['src_dir']
            vars_file.puts("src_dir: /usr/local/src")
          else
            vars_file.puts("src_dir: #{software['src_dir']}")
          end
        end

      end
    end 

    # setting
    return unless @vulconfig.key?('setting')
    vultest_ansible_role_setting_dir = "#{@vultest_ansible_roles_dir}/#{@vulconfig['cve']}"
    FileUtils.mkdir_p("#{vultest_ansible_role_setting_dir}/tasks")
    FileUtils.cp_r("#{@vulconfig['setting']}/tasks/main.yml", "#{vultest_ansible_role_setting_dir}/tasks/main.yml")

  end

  def create_ansible_playbook
    File.open("#{@vultest_ansible_playbook_dir}/main.yml", "w") do |playbook_file|
      playbook_file.puts("---")
      playbook_file.puts("- hosts: vagrant")
      playbook_file.puts("  connection: local ")
      playbook_file.puts("  become: yes ")
      playbook_file.puts("  roles: ")

      # add roles in playbook
      if @vulconfig.key?('software')
        softwares = @vulconfig['software']
        softwares.each do |software|
          playbook_file.puts("    - ../roles/#{software['name']} ")
        end
      end

      playbook_file.puts("    - ../roles/#{@vulconfig['cve']} ") if @vulconfig.key?('setting')
      playbook_file.puts("    - ../roles/metasploit") if @vulconfig['attack_vector'] == 'local' 
    end
  end

  def create_vagrant_ansible_dir
    self.create_vagrantfile
    self.create_ansible_dir
    self.create_ansible_config
    self.create_ansible_hosts
    self.create_ansible_role
    self.create_ansible_playbook
  end

  def get_attack_vector
    return @vulconfig['attack_vector']
  end

  def get_caution
    return nil unless @vulconfig.key?('caution')
    return @vulconfig['caution']
  end

end
