require 'open3'
require 'sqlite3'
require 'tty-table'

require_relative './attack/msf'
require_relative './create_env'
require_relative './utility'

module Vultest

  def attack
    # Connection Metasploit API
    if @rhost.nil?
      @rhost = '192.168.33.10'
    end
    msf_api = MetasploitAPI.new(@rhost)
    msf_api.auth_login
    msf_api.console_create

    # Lead yaml file
    msf_module_config = YAML.load_file("./#{@attack_config_file_path}")
    msf_modules = msf_module_config['metasploit_module']

    Utility.print_message('execute', 'exploit attack')

    execute_session_count = 0
    msf_modules.each do |msf_module|
      msf_module_type = msf_module['module_type']
      msf_module_name = msf_module['module_name']

      options = msf_module['options']
      msf_module_option = {}
      options.each do |option|
        msf_module_option[option['name']] = option['var']
      end

      msf_module_option['LHOST'] = @rhost
      msf_module_info = msf_api.module_execute(msf_module_type, msf_module_name, msf_module_option)

      i = 0
      session_connection_flag = false

      Utility.tty_spinner_begin(msf_module['module_name'])
      loop do
        sleep(1)
        msf_session_list = msf_api.module_session_list
        msf_session_list.each do |session_info_key, session_info_value|
          session_connection_flag = true if msf_module_info['uuid'] == session_info_value['exploit_uuid']
        end
        break if i > 600 || session_connection_flag
        i += 1
      end
      session_connection_flag ? Utility.tty_spinner_end('success') : Utility.tty_spinner_end('error')
      execute_session_count += 1
    end

    # Execute demo
    Utility.print_message('execute', 'execute demo')
    # Meterpreter is used by last session.
    # execute_session_count is last session.

    # If there isn't next code, any commnand is "command not found"
    sleep(30)

    # Execute command
    msf_api.meterpreter_write(execute_session_count.to_i, 'getuid')
    meterpreter_res = msf_api.meterpreter_read(execute_session_count.to_i)
    loop do
      sleep(1)
      meterpreter_res = msf_api.meterpreter_read(execute_session_count.to_i)
      break unless meterpreter_res['data'].empty?
    end

    puts meterpreter_res['data']
  end

  def exit
    @rhost = nil
    @attack_vector_file_path = nil
  end

  def set_rhost(rhost)
    @rhost = rhost
  end

  def start_up(cve)
    #create database
    db = SQLite3::Database.new('./db/vultest.db')
    db.results_as_hash = true

    # Use to set ip address for machine of attack
    attack_vector_list = []
    # Use to set option of attack
    attack_config_file_path_list = []
    # Use to set config file
    vul_env_config_list = []
    # Use anounce env caution
    env_caution_list = []

    cnt = 0
    db.execute('select * from configs where cve_name=?', cve) do |config|
      # create environment
      vulenv = CreateEnv.new("./#{config['config_path']}", cnt)
      vulenv.create_vagrant_ansible_dir
      attack_vector = vulenv.get_attack_vector
      env_caution = vulenv.get_caution

      attack_vector_list.push(attack_vector)
      env_caution_list.push(env_caution)
      vul_env_config_list.push([cnt, "./test/vulenv_#{cnt}"])
      attack_config_file_path_list.push(config['module_path'])
      cnt += 1
    end
    db.close

    # Can create list which is environment of vulnerability
    Utility.print_message('caution', 'vulnerability environment list')
    header = ['id', 'vulnerability environment path']
    table = TTY::Table.new header, vul_env_config_list
    table.render(:ascii).each_line do |line|
      puts line.chomp
    end
    print "\n"

    id_list = []
    vul_env_config_list.each do |id, vul_env_path|
      id_list.push(id.to_s)
    end
    # Select environment of vulnerability by id
    message = 'Select an id for testing vulnerability envrionment?'
    select_id = Utility.tty_prompt(message, id_list)
    # Select file which is configure of attack
    @attack_config_file_path = attack_config_file_path_list[select_id.to_i]

    # start up environment of vulnerability
    Utility.print_message('execute', 'create vulnerability environment')
    Dir.chdir("./test/vulenv_#{select_id}") do
      Utility.tty_spinner_begin('start up')
      stdout, stderr, status = Open3.capture3('vagrant up')

      if status.exitstatus != 0
        reload_stdout, reload_stderr, reload_status = Open3.capture3('vagrant reload')
        if reload_status.exitstatus != 0
          Utility.tty_spinner_end('error')
          exit!
        end
      end

      reload_status, reload_stderr, reload_status = Open3.capture3('vagrant reload')
      if reload_status.exitstatus != 0 
        Utility.tty_spinner_end('error')
        exit!
      end

      Utility.tty_spinner_end('success')

      # When tool cannot change setting, tool want user to change setting
      unless env_caution_list[select_id.to_i].nil?
        env_caution_reload_flag = false
        env_caution_list[select_id.to_i].each do |env_caution|
          if env_caution['type'] == 'reload'
            Utility.print_message('caution', env_caution['msg'])
            unless env_caution_reload_flag
              Open3.capture3('vagrant halt')
              env_caution_reload_flag = true
            end
          end
        end

        if env_caution_reload_flag
          Utility.print_message('default','Please enter key when ready')
          input = gets

          Utility.tty_spinner_begin('reload')
          stdout, stderr, status = Open3.capture3('vagrant up')
          if status.exitstatus != 0
            Utility.tty_spinner_end('error')
            exit!
          end
          Utility.tty_spinner_end('success')
        end
      end
    end

    if attack_vector_list[select_id.to_i] == 'local'
      Utility.print_message('caution', 'attack vector is local')
      Utility.print_message('caution', 'following execute command')
      message = <<-EOS
      [1] vagrant ssh
      [2] sudo su - msf
      [3] cd metasploit-framework
      [4] ./msfconsole
      [5] load msgrpc ServerHost=192.168.33.10 ServerPort=55553 User=msf Pass=metasploit
      EOS
      Utility.print_message('default', message)
      @rhost = '192.168.33.10'
    else
      Utility.print_message('caution', 'input ip address of machine for attack')
      Utility.print_message('caution', 'start up kali linux')
    end
  end

  module_function :attack
  module_function :set_rhost
  module_function :start_up
end
