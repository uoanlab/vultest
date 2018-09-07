require 'open3'
require 'pastel'
require 'sqlite3'
require 'tty-command'
require 'tty-font'
require 'tty-prompt'
require 'tty-table'
require 'tty-spinner'
require 'yaml'

require_relative 'lib/create_env'
require_relative 'lib/metasploit/msf'

def create_vulenv_dir(cve)
  # create database
  db = SQLite3::Database.new("./db/vultest.db")
  db.results_as_hash = true

  attack_vector_list = []
  vul_env_config_list = []
  attack_config_file_path_list = []

  cnt = 0
  db.execute('select * from configs where cve_name=?', "#{cve}") do |config|
    # create environment
    vulenv = CreateEnv.new("./#{config['config_path']}", "#{cnt}")
    vulenv.create_vagrantfile
    vulenv.create_ansible_dir
    vulenv.create_ansible_config
    vulenv.create_ansible_hosts
    vulenv.create_ansible_role
    vulenv.create_ansible_playbook
    attack_vector = vulenv.get_attack_vector

    attack_vector_list.push(attack_vector)
    vul_env_config_list.push([cnt, "./vultest/vulenv_#{cnt}"])
    attack_config_file_path_list.push(config['module_path'])

    cnt += 1
  end

  return attack_vector_list, vul_env_config_list, attack_config_file_path_list
end

def create_vulenv(id)
  puts "[*] create vulnerability environment"
  Dir.chdir("./vultest/vulenv_#{id}") do
    vagrant_up_spinner = TTY::Spinner.new("[:spinner] vagrant up", success_mark: '+', error_mark: 'x')
    vagrant_up_spinner.auto_spin
    stdout, stderr, status = Open3.capture3('vagrant up')

    # when vagrant up is fail
    if status.exitstatus != 0 then
      vagrant_up_spinner.error

      vagrant_reload_spinner = TTY::Spinner.new("[:spinner] vagrant reload", success_mark: '+', error_mark: 'x')
      vagrant_reload_spinner.auto_spin
      Open3.capture3('vagrant reload')
      vagrant_reload_spinner.success
    else
      vagrant_up_spinner.success
    end

    puts '[*] restart vulnerability environment'
    vagrant_reload_spinner = TTY::Spinner.new("[:spinner] vagrant reload", success_mark: '+', error_mark: 'x')
    vagrant_reload_spinner.auto_spin
    Open3.capture3('vagrant reload')
    vagrant_reload_spinner.success
  end
end

def attack(host, config_file_path)
  # Metasploit APIと接続
  msf_api = MetasploitAPI.new(host)
  msf_api.auth_login_module
  msf_api.console_create_module

  #yamlファイルを読み込む
  msf_module_config = YAML.load_file("./#{config_file_path}")
  msf_modules = msf_module_config['metasploit_module']
  puts '[*] exploit attack'

  msf_modules.each do |msf_module|
    msf_module_type = msf_module['module_type']
    msf_module_name = msf_module['module_name']

    options = msf_module['options']
    msf_module_option = {}
    options.each do |option|
      msf_module_option[option['name']] = option['var']
    end

    msf_module_info = msf_api.module_execute_module(msf_module_type, msf_module_name, msf_module_option)

    i = 0
    session_connection_flag = false

    module_spinner = TTY::Spinner.new("[:spinner] #{msf_module['module_name']}", success_mark: '+', error_mark: 'x')
    module_spinner.auto_spin
    loop do
      sleep(1)
      msf_session_list = msf_api.module_session_list
      msf_session_list.each do |session_info_key, session_info_value|
        if msf_module_info['uuid'] == session_info_value['exploit_uuid'] then
          session_connection_flag = true
          break
        end
      end
      break if i > 1200 || session_connection_flag
      i += 1
    end

    if session_connection_flag then
      module_spinner.success
    else
      module_spinner.error
    end
  end

end

if __FILE__ == $0
  font = TTY::Font.new(:"3d")
  pastel = Pastel.new
  puts pastel.red(font.write("VULTEST"))

  loop do
    print 'vultest >'
    command = gets
    command = command.chomp!

    command_line = command.split(" ")

    # test command
    if command_line[0] == 'test' then
      attack_vector_list, vul_env_config_list, attack_config_file_path_list = create_vulenv_dir(command_line[1])

      header = ['id', 'vulnerability environment path']
      table = TTY::Table.new header, vul_env_config_list

      puts '[l] vulnerability environment list'
      table.render(:ascii).each_line do |line|
        puts line.chomp
      end
      print "\n"

      id_list = []
      vul_env_config_list.each do |id, vul_env_path|
        id_list.push(id.to_s)
      end
      prompt = TTY::Prompt.new
      id = prompt.enum_select('[!] Select an id for testing vulnerability envrionment?', id_list)

      create_vulenv(id)

      if attack_vector_list[id.to_i] == 'local' then
        puts '[!] attack vector is local'
        puts '[!] following execute command'
        puts '[1] vagrant ssh'
        puts '[2] sudo su - msf'
        puts '[3] cd metasploit-framework'
        puts '[4] ./msfconsole'
        puts '[5] load msgrpc ServerHost=192.168.33.10 ServerPort=55553 User=msf Pass=metasploit '

        host = '192.168.33.10'
      else 
        host = '192.168.33.77'
      end

      loop do
        print "#{command_line[1]}> "
        exploit_command = gets
        exploit_command = exploit_command.chomp!

        if exploit_command == 'exploit' then
          attack(host, attack_config_file_path_list[id.to_i])
        elsif exploit_command == 'exit' then
          break
        end

      end

    # exit command
    elsif command_line[0] == 'exit' then
      break
    # command (ls, echo etc)
    else
      cmd = TTY::Command.new
      cmd.run(command)
    end

  end

end
