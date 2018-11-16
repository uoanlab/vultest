require 'open3'
require 'sqlite3'
require 'tty-table'

require_relative './attack/msf'
require_relative './create_env'
require_relative './db'
require_relative './utility'
require_relative './prompt'

class Vultest

  def initialize(cve)
    @cve = cve
    @attack_machine_host = nil
    @attack_config_path = nil
    @vulenv_config_path = nil
    @vulenv_config_detail = nil 

    #attack tool
    @msf_api = nil
  end

  def attack
    # Connection Metasploit API
    if @attack_machine_host.nil?
      @attack_machine_host = '192.168.33.10'
    end
    @msf_api = MetasploitAPI.new(@attack_machine_host)
    @msf_api.auth_login
    @msf_api.console_create

    # Lead yaml file
    msf_module_config = YAML.load_file(@attack_config_path)
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

      msf_module_option['LHOST'] = @attack_machine_host
      msf_module_info = @msf_api.module_execute(msf_module_type, msf_module_name, msf_module_option)

      exploit_time = 0
      session_connection_flag = false

      Utility.tty_spinner_begin(msf_module['module_name'])
      loop do
        sleep(1)
        msf_session_list = @msf_api.module_session_list
        msf_session_list.each do |session_info_key, session_info_value|
          session_connection_flag = true if msf_module_info['uuid'] == session_info_value['exploit_uuid']
        end
        break if exploit_time > 600 || session_connection_flag
        exploit_time += 1
      end
      session_connection_flag ? Utility.tty_spinner_end('success') : Utility.tty_spinner_end('error')
    end
  end

  def attack_verify
    Utility.print_message('execute', 'execute verify')

    # Use meterpreter by metasploit
    session_type = nil
    session_id = nil
    @msf_api.module_session_list.each do |session_info_key, session_info_value|
      session_id = session_info_key if session_info_value['type'] == 'meterpreter' || session_info_value['type'] == 'shell'
      session_type = session_info_value['type'] unless session_id.nil?
    end
    return if session_id.nil?

    session_prompt = Prompt.new(session_type)
    loop do
      session_prompt.print_prompt
      input_command = session_prompt.get_input_command
      # When input next line
      next if input_command.nil?
      break if input_command == 'exit'
      if session_type == 'meterpreter'
        @msf_api.meterpreter_write(session_id, input_command)
      elsif session_type == 'shell'
        @msf_api.shell_write(session_id, input_command)
      end
      loop do
        sleep(1)
        res = {}
        if session_type == 'meterpreter'
          res = @msf_api.meterpreter_read(session_id)
        elsif session_type == 'shell'
          res = @msf_api.shell_read(session_id)
        end
        unless res['data'].empty?
          puts res['data']
          break
        end
      end
    end
  end

  def prepare_attack
    if @vulenv_config_detail['attack_vector'] == 'local'
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
      if @vulenv_config_detail.key?('caution')
        @vulenv_config_detail['caution'].each do |env_caution|
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
      Utility.print_message('caution', "command is 'set' for setting ip address")
      Utility.print_message('caution', 'ex) set attacker 192.168.33.10')
      Utility.print_message('caution', 'start up kali linux')
    end
  end

  def prepare_vulenv
    vulenv = CreateEnv.new(@vulenv_config_path)
    vulenv.create_vagrant_ansible_dir

    # start up environment of vulnerability
    Utility.print_message('execute', 'create vulnerability environment')
    Dir.chdir("./test") do
      Utility.tty_spinner_begin('start up')
      stdout, stderr, status = Open3.capture3('vagrant up')

      if status.exitstatus != 0
        reload_stdout, reload_stderr, reload_status = Open3.capture3('vagrant reload')

        if reload_status.exitstatus != 0
          Utility.tty_spinner_end('error')
          return 'error'
        end
      end

      if @vulenv_config_detail.key?('reload')
        reload_status, reload_stderr, reload_status = Open3.capture3('vagrant reload')
        if reload_status.exitstatus != 0 
          Utility.tty_spinner_end('error')
          return 'error'
        end
      end

      Utility.tty_spinner_end('success')

      # When tool cannot change setting, tool want user to change setting
      if @vulenv_config_detail.key?('caution')
        vulenv_caution_setup_flag = false
        @vulenv_config_detail['caution'].each do |vulenv_caution|
          if vulenv_caution['type'] == 'setup'
            vulenv_caution['msg'].each do |msg|
              Utility.print_message('caution', msg)
            end
            Open3.capture3('vagrant halt')
            vulenv_caution_setup_flag = true
          end
        end

        if vulenv_caution_setup_flag
          Utility.print_message('default','Please enter key when ready')
          input = gets

          Utility.tty_spinner_begin('reload')
          stdout, stderr, status = Open3.capture3('vagrant up')
          if status.exitstatus != 0
            Utility.tty_spinner_end('error')
            return 'error'
          end
          Utility.tty_spinner_end('success')
        end
      end
    end
  end

  def report

    Utility.print_message('default', 'vultest report')
    Utility.print_message('default', "==============")

    # Get CVE description
    cve_info = DB.get_cve_info(@cve)
    unless cve_info['description'].nil?
      for str_range in 1..cve_info['description'].size/100
        new_line_place = cve_info['description'].index(" ", str_range * 100) + 1
        cve_info['description'].insert(new_line_place, "\n    ")
      end
    end
    print "\n"

    Utility.print_message('defalut', '  CVE description')
    Utility.print_message('defalut', "  ===============")
    print "\n"
    Utility.print_message('defalut', "    #{cve_info['description']}")
    print "\n"

    # Get cpe
    Utility.print_message('default', '  Affect system (CPE)')
    Utility.print_message('defalut', "  ==================")
    print "\n"
    cpe = DB.get_cpe(@cve)
    cpe.each do |cpe_info|
      Utility.print_message('defalut', "    #{cpe_info}")
    end
    print "\n"

    # Verfiy target
    Utility.print_message('default', '  Verfiy target')
    Utility.print_message('defalut', "  ===============")
    print "\n"

    Utility.print_message('default', "    #{@vulenv_config_detail['os']['name']}:#{@vulenv_config_detail['os']['version']}")
    softwares = @vulenv_config_detail['software']
    softwares.each do |software|
      if software.key?('version')
        Utility.print_message('default', "    #{software['name']}:#{software['version']}")
      else
        install_command = ''
        if software['os_depend']
          if @vulenv_config_detail['os']['name'] == 'ubuntu'
            install_command = "apt-get install #{software['name']}"
          elsif @vulenv_config_detail['os']['name'] == 'centos'
            install_command = "yum install #{software['name']}"
          end
          Utility.print_message('default', "    #{software['name']}:default(#{install_command})")
        else
          Utility.print_message('default', "    #{software['name']}:default")
        end
      end
    end
    print "\n"

    # Unique configure
    first_flag = true
    if @vulenv_config_detail.key?('caution')
      @vulenv_config_detail['caution'].each do |messages|
        if messages['type'] == 'report' || messages['type'] == 'setup'
          if first_flag
            Utility.print_message('default', '  Unique configure')
            Utility.print_message('defalut', "  ================")
            first_flag = false
          end
          messages['msg'].each do |message|
            Utility.print_message('defalut', "    #{message}")
          end
        end
      end
    end
    print "\n"

  end

  def set_attack_machine_host(attack_machine_host)
    @attack_machine_host = attack_machine_host
  end

  def select_vulenv
    config = YAML.load_file('./config.yml')
    vulconfigs = DB.get_vulconfigs(@cve)

    table_index = 0
    vulenv_name_list = []
    vulenv_table = []
    vulenv_index_info = {}
    vulconfigs.each do |vulconfig|
      vulenv_table.push([table_index, vulconfig['name']])
      vulenv_index_info[vulconfig['name']] = table_index
      vulenv_name_list.push(vulconfig['name'])
      table_index += 1
    end

    return 'error' if table_index == 0

    # Can create list which is environment of vulnerability
    Utility.print_message('output', 'vulnerability environment list')
    header = ['id', 'vulenv name']
    table = TTY::Table.new header, vulenv_table
    table.render(:ascii).each_line do |line|
      puts line.chomp
    end
    print "\n"

    # Select environment of vulnerability by id
    message = 'Select an id for testing vulnerability envrionment?'
    select_vulenv_name = Utility.tty_prompt(message, vulenv_name_list)
    select_id = vulenv_index_info[select_vulenv_name]

    @vulenv_config_path = "#{config['vultest_db_path']}/#{vulconfigs[select_id.to_i]['config_path']}"
    @attack_config_path = "#{config['vultest_db_path']}/#{vulconfigs[select_id.to_i]['module_path']}"
    @vulenv_config_detail = YAML.load_file(@vulenv_config_path)
  end

  def vulenv_destroy
    Dir.chdir("./test") do
      Utility.tty_spinner_begin('vulent destroy')
      stdout, stderr, status = Open3.capture3('vagrant destroy -f')
      if status.exitstatus != 0
        Utility.tty_spinner_end('error')
        exit!
      end
    end

    Dir.chdir(".") do
      stdout, stderr, status = Open3.capture3('rm -rf test')
      if status.exitstatus != 0
        Utility.tty_spinner_end('error')
        exit!
      end
    end

    Utility.tty_spinner_end('success')
  end

end

