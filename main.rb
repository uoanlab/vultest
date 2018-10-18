require_relative './prompt'
require_relative './report'
require_relative './utility'
require_relative './vultest'

prompt = Prompt.new('vultest')
prompt.title
cve = nil

loop do
  prompt.print_prompt
  input_list = prompt.get_input_command_list

  # default prompt
  if input_list[0] == 'test'
    unless input_list[1].nil?
      cve = input_list[1]
    end
    Vultest.start_up(cve)
    prompt.set_prompt(cve)
  elsif input_list[0] == 'exit'
    exit!
  end

  #vultest prompt
  if input_list[0] == 'exploit'
    Vultest.attack
  elsif input_list[0] == 'rhost'
    Vultest.set_rhost(input_list[1])
    Utility.print_message('caution', 'start up metasploit by kail linux')
    Utility.print_message('caution', "load msgrpc ServerHost=#{input_list[1]} ServerPort=55553 User=msf Pass=metasploit")
  elsif input_list[0] == 'back'
    Vultest.exit
    prompt.set_prompt('vultest')
  elsif input_list[0] == 'report'
    unless input_list[1].nil?
      cve = input_list[1]
    end
    Report.print_cve(cve)
    Report.print_cvss_v2(cve)
    Report.print_cvss_v3(cve)
  end

end
