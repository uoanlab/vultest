require 'open3'
require 'sqlite3'
require 'tty-table'

require_relative './attack/msf'
require_relative './create_env'
require_relative './db'
require_relative './utility'
require_relative './prompt'

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

      exploit_time = 0
      session_connection_flag = false

      Utility.tty_spinner_begin(msf_module['module_name'])
      loop do
        sleep(1)
        msf_session_list = msf_api.module_session_list
        msf_session_list.each do |session_info_key, session_info_value|
          session_connection_flag = true if msf_module_info['uuid'] == session_info_value['exploit_uuid']
        end
        break if exploit_time > 600 || session_connection_flag
        exploit_time += 1
      end
      session_connection_flag ? Utility.tty_spinner_end('success') : Utility.tty_spinner_end('error')
    end

    # Execute demo
    Utility.print_message('execute', 'execute demo')

    # Use meterpreter by metasploit
    meterpreter_session_id = nil
    msf_api.module_session_list.each do |session_info_key, session_info_value|
      meterpreter_session_id = session_info_key if session_info_value['type'] == 'meterpreter'
    end
    return if meterpreter_session_id.nil?

    meterpreter_prompt = Prompt.new('meterpreter')
    loop do
      meterpreter_prompt.print_prompt
      input_command = meterpreter_prompt.get_input_command
      # When input next line
      next if input_command.nil?
      break if input_command == 'exit'
      msf_api.meterpreter_write(meterpreter_session_id, input_command)
      meterpreter_time = 0
      loop do
        sleep(1)
        meterpreter_res = msf_api.meterpreter_read(meterpreter_session_id)
        unless meterpreter_res['data'].empty?
          puts meterpreter_res['data']
          break
        end
      end
    end

  end

  def exit
    @rhost = nil
    @attack_vector_file_path = nil
  end

  def set_rhost(rhost)
    @rhost = rhost
  end

  def set_attack_config_file_path(file_path)
    @attack_config_file_path = file_path
  end

  def start_up(cve)
    vulconfigs = DB.get_vulconfigs(cve)

    #to do
    index = 0
    id_list = []
    vulenv_configs_path = []
    vulconfigs.each do |vulconfig|
      vulenv_configs_path.push([index, vulconfig['config_path']])
      id_list.push(index.to_s)
      index += 1
    end

    # Can create list which is environment of vulnerability
    Utility.print_message('output', 'vulnerability environment list')
    header = ['id', 'vulnerability environment path']
    table = TTY::Table.new header, vulenv_configs_path
    table.render(:ascii).each_line do |line|
      puts line.chomp
    end
    print "\n"

    # Select environment of vulnerability by id
    message = 'Select an id for testing vulnerability envrionment?'
    select_id = Utility.tty_prompt(message, id_list)

    # Create and setting environment of vultest
    vulenv = CreateEnv.new("./#{vulconfigs[select_id.to_i]['config_path']}")
    vulenv.create_vagrant_ansible_dir
    vulenv_config_detail = YAML.load_file("./#{vulconfigs[select_id.to_i]['config_path']}")
    self.set_attack_config_file_path(vulconfigs[select_id.to_i]['module_path'])

    # start up environment of vulnerability
    Utility.print_message('execute', 'create vulnerability environment')
    Dir.chdir("./test") do
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
      if vulenv_config_detail.key?('caution')
        env_caution_setup_flag = false
        env_caution_list[select_id.to_i].each do |env_caution|
          if env_caution['type'] == 'setup'
            env_caution['msg'].each do |msg|
              Utility.print_message('caution', msg)
            end
            Open3.capture3('vagrant halt')
            env_caution_setup_flag = true
          end
        end

        if env_caution_setup_flag
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

    if vulenv_config_detail['attack_vector'] == 'local'
      Utility.print_message('caution', 'attack vector is local')
      Utility.print_message('caution', 'following execute command')
      message = <<-EOS
  [1] cd ./test
  [2] vagrant ssh
  [3] sudo su - msf
  [4] cd metasploit-framework
  [5] ./msfconsole
  [6] load msgrpc ServerHost=192.168.33.10 ServerPort=55553 User=msf Pass=metasploit
      EOS
      Utility.print_message('default', message)
    else
      if vulenv_config_detail.key?('caution')
        vulenv_config_detail['caution'].each do |env_caution|
          if env_caution['type'] == 'start-up'
            Utility.print_message('caution', 'following execute command')
            Utility.print_message('defalut', '  [1] cd ./test')
            Utility.print_message('default', '  [2] vagrant ssh')
            code_procedure = 3
            env_caution['msg'].each do |msg|
              msg = "  [#{code_procedure}] #{msg}"
              Utility.print_message('default', msg)
              code_procedure += 1
            end
          end
        end
      end
      Utility.print_message('caution', 'input ip address of machine for attack')
      Utility.print_message('caution', 'start up kali linux')
    end
  end

  module_function :attack
  module_function :exit
  module_function :set_rhost
  module_function :set_attack_config_file_path
  module_function :start_up

end
