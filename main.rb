require_relative './prompt'
require_relative './vulinfo'
require_relative './utility'
require_relative './vultest'

prompt = Prompt.new('vultest')
prompt.title
cve = nil
vultest = nil

loop do
  prompt.print_prompt
  input_list = prompt.get_input_command_list

  # default prompt
  if input_list[0] == 'test'
    unless input_list[1].nil?
      cve = input_list[1]
    end
    vultest = Vultest.new(cve)
    vultest.select_vulenv
    vultest.prepare_vulenv
    vultest.prepare_attack
    prompt.set_prompt(cve)
  elsif input_list[0] == 'exit'
    exit!
  end

  #vultest prompt
  if input_list[0] == 'exploit'
    vultest.attack
  elsif input_list[0] == 'rhost'
    vultest.set_rhost(input_list[1])
    Utility.print_message('caution', 'start up metasploit by kail linux')
    Utility.print_message('caution', "load msgrpc ServerHost=#{input_list[1]} ServerPort=55553 User=msf Pass=metasploit")
  elsif input_list[0] == 'back'
    vultest.vulenv_destroy
    vultest = nil
    prompt.set_prompt('vultest')
  elsif input_list[0] == 'info'
    unless input_list[1].nil?
      cve = input_list[1]
    end
    Vulinfo.print_cve(cve)
    Vulinfo.print_cvss_v2(cve)
    Vulinfo.print_cvss_v3(cve)
  elsif input_list[0] == 'report'
    vultest.report
    vultest.attack_verify
  end

end
