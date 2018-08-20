require 'sqlite3'
require 'yaml'

require_relative 'create_env'
require_relative 'msf'

puts 'CVEを入力してください'
puts '例　CVE-2016-4557'
cve = gets
cve = cve.chomp!

db = SQLite3::Database.new("./db/vultest.db")
db.results_as_hash = true

cnt = 0
db.execute('select * from configs where cve_name=?', "#{cve}") do |config|
  # 環境作成
  vulenv = CreateEnv.new("./#{config['config_path']}", "#{cnt}")
  vulenv.create_vagrantfile
  vulenv.create_ansible_dir
  vulenv.create_ansible_config
  vulenv.create_ansible_hosts
  vulenv.create_ansible_role
  vulenv.create_ansible_playbook
  vulenv.creat_start_script

  puts "攻撃対象の環境: ./vultest/vulenv_#{cnt}"
  puts '---------------------環境を作成するコマンド----------------------'
  puts "$ cd ./vultest/vulenv_#{cnt}"
  puts '$ ./start.sh'
  puts '-----------------------------------------------------------------'
  print "\n"
  puts '------------------------攻撃の準備を作成-------------------------'
  puts '$ vagrant ssh'
  puts '$ sudo su - msf'
  puts '$ cd metasploit-framework'
  puts '$ ./msfconsole'
  puts '$ load msgrpc ServerHost=192.168.33.10 ServerPort=55553 User=msf Pass=metasploit '
  puts '-----------------------------------------------------------------'
  print "\n"

  puts '攻撃を行う時は、attackと入力してください'
  print "command >> "
  attack = gets

  # Metasploit APIと接続
  msf_api = MetasploitAPI.new()
  msf_api.auth_login_module
  msf_api.console_create_module

  msf_module_config = YAML.load_file("./#{config['module_path']}")
  msf_modules = msf_module_config['metasploit_module']

  msf_modules.each do |msf_module|
    msf_module_type = msf_module['module_type']
    msf_module_name = msf_module['module_name']

    options = msf_module['options']
    msf_module_option = {}
    options.each do |option|
      msf_module_option[option['name']] = option['var']
    end

    msf_moudle_info = msf_api.module_execute_module(msf_module_type, msf_module_name, msf_module_option)
    sleep(msf_module['proces_time'])

  end

  puts '攻撃が完了しました'
  print "\n"

  puts '攻撃の情報'
  console_read_res = msf_api.console_read_module
  for data in console_read_res['data'].split(/\R/)
    puts data
  end
  print "\n"

  puts '---------------------環境を削除するコマンド----------------------'
  puts '$ exit -y'
  puts '$ exit'
  puts '$ exit'
  puts '$ vagrant destory'
  puts '-----------------------------------------------------------------'
  print "\n"

  cnt += 1
end
