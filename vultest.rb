require 'open3'
require 'pp'
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

  puts "攻撃対象の環境: ./vultest/vulenv_#{cnt}"

  puts '仮想環境の作成'
=begin
  Dir.chdir("./vultest/vulenv_#{cnt}") do
    stdout, stderr, status = Open3.capture3('vagrant up')

    if status.exitstatus != 0
      Open3.capture3('vagrant reload')
    end
    stdout, stderr, status = Open3.capture3('vagrant reload')
  end
=end
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

    msf_module_info = msf_api.module_execute_module(msf_module_type, msf_module_name, msf_module_option)

    puts "#{msf_module['module_name']}を実行中"
    i = 0
    loop do
      sleep(1)
      session_connection_flag = false
      msf_session_list = msf_api.module_session_list
      msf_session_list.each do |session_info_key, session_info_value|
        if msf_module_info['uuid'] == session_info_value['exploit_uuid'] then
          session_connection_flag = true
          break
        end
      end
      if session_connection_flag then
        break
      else
        if i > 1200 then
          puts '攻撃が失敗しました'
          print "\n"
          exit
        else 
          i += 1
        end
      end
    end

  end

  puts '攻撃が完了しました'
  print "\n"

  puts '攻撃の情報'
  console_read_res = msf_api.console_read_module
  for data in console_read_res['data'].split(/\R/)
    puts data
  end
  print "\n"

  puts '仮想環境の削除'
  Dir.chdir("./vultest/vulenv_#{cnt}") do
    stdout, stderr, status = Open3.capture3('vagrant destroy')
  end

  cnt += 1
end
