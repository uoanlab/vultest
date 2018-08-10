require 'fileutils'
require 'sqlite3'
require 'yaml'

# 脆弱性の存在する環境を作成するための、ディレクトリとファイルを作成
class CreateEnv

  def initialize(vulconfig_file, cnt)
    @vultest_dir = "./vultest/vulenv_#{cnt}"
    FileUtils.mkdir_p("#{@vultest_dir}")

    @vulconfig = YAML.load_file("#{vulconfig_file}")
  end

  # OSの情報を元に、Vagrantfileを作成(コピー)
  def create_vagrantfile
    vagrantfile_dir = "./build/vagrant/#{@vulconfig['os']['name']}/#{@vulconfig['os']['version']}/Vagrantfile"
    FileUtils.cp_r("#{vagrantfile_dir}", "#{@vultest_dir}/Vagrantfile")
  end

  def create_ansible_dir
    # 脆弱性の環境を作成するために使うansibleのディレクトリのパス
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

    #attack vector localの時
    FileUtils.mkdir_p("#{@vultest_ansible_roles_dir}/metasploit")
    FileUtils.mkdir_p("#{@vultest_ansible_roles_dir}/metasploit/tasks")
    FileUtils.mkdir_p("#{@vultest_ansible_roles_dir}/metasploit/vars")
    FileUtils.mkdir_p("#{@vultest_ansible_roles_dir}/metasploit/files")

    ansible_role_metasploit_dir = "./build/ansible/roles/metasploit"
    FileUtils.cp_r("#{ansible_role_metasploit_dir}/tasks/main.yml", "#{@vultest_ansible_roles_dir}/metasploit/tasks/main.yml")
    FileUtils.cp_r("#{ansible_role_metasploit_dir}/vars/main.yml", "#{@vultest_ansible_roles_dir}/metasploit/vars/main.yml")
    FileUtils.cp_r("#{ansible_role_metasploit_dir}/files/database.yml", "#{@vultest_ansible_roles_dir}/metasploit/files/database.yml")

    softwares = @vulconfig['software']
    softwares.each do |software|
      # 脆弱性の環境を作成するために使うansibleのrolesのディレクトリのパス
      vultest_ansible_role_software_dir = "#{@vultest_ansible_roles_dir}/#{software['name']}"

      # tasksを作成
      FileUtils.mkdir_p("#{vultest_ansible_role_software_dir}/tasks")
      ansible_role_dir = "./build/ansible/roles/#{software['name']}"
      FileUtils.cp_r("#{ansible_role_dir}/tasks/main.yml", "#{vultest_ansible_role_software_dir}/tasks/main.yml")
 
      # varsを作成
      FileUtils.mkdir_p("#{vultest_ansible_role_software_dir}/vars")
      File.open("#{vultest_ansible_role_software_dir}/vars/main.yml", "w") do |vars_file|
        vars_file.puts("---")

        packages = software['package']
        packages.each do |package|
          vars_file.puts("#{package['name']}: #{package['version']}")
        end
      end
    end
  end

 def create_ansible_playbook
  File.open("#{@vultest_ansible_playbook_dir}/main.yml", "w") do |playbook_file|
    playbook_file.puts("---")
    playbook_file.puts("- hosts: vagrant")
    playbook_file.puts("  connection: local ")
    playbook_file.puts("  become: yes ")
    playbook_file.puts("  roles: ")

    #playbookにrolesを追加
    softwares = @vulconfig['software']
    softwares.each do |software|
      playbook_file.puts("    - ../roles/#{software['name']} ")
    end

    #attack vector が　localの時
    playbook_file.puts("    - ../roles/metasploit")

  end
 end

 def creat_start_script
  File.open("#{@vultest_dir}/start.sh", "w") do |start_file|
    start_file.puts("#!/bin/sh")
    start_file.puts("vagrant up")
    start_file.puts("vagrant reload")
    start_file.puts("vagrant ssh")
  end
  FileUtils.chmod(0755, "#{@vultest_dir}/start.sh")
 end

end


p 'CVEを入力してください'
p '例　CVE-2017-16995'
cve = gets
cve = cve.chomp!

db = SQLite3::Database.new("./db/vultest.db")
db.results_as_hash = true

cnt = 0
db.execute('select * from configs where cve_name=?', "#{cve}") do |config|
  vulenv = CreateEnv.new("./#{config['config_path']}", "#{cnt}")
  vulenv.create_vagrantfile
  vulenv.create_ansible_dir
  vulenv.create_ansible_config
  vulenv.create_ansible_hosts
  vulenv.create_ansible_role
  vulenv.create_ansible_playbook
  vulenv.creat_start_script
  cnt += 1
end
