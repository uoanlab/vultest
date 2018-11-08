require 'bundler/setup'

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

  case input_list[0]
  when 'test'
    unless input_list[1].nil?
      cve = input_list[1]
    end

    vultest = Vultest.new(cve)
    if vultest.select_vulenv == 'error'
      Utility.print_message('error', 'Cannot test vulnerability')
      vultest = nil
      next
    end

    if vultest.prepare_vulenv == 'error'
      Utility.print_message('error', 'Cannot start up vulenv')
      vultest = nil
      next
    end

    vultest.prepare_attack
    prompt.set_prompt(cve)

  when 'exit'
    break

  when 'exploit'
    vultest.attack unless vultest.nil?

  when 'set'
    if input_list[1] == 'attacker'
      vultest.set_attack_machine_host(input_list[2])
      Utility.print_message('caution', 'start up metasploit by kail linux')
      Utility.print_message('caution', "load msgrpc ServerHost=#{input_list[2]} ServerPort=55553 User=msf Pass=metasploit")
    end

  when 'back'
    vultest.vulenv_destroy
    vultest = nil
    prompt.set_prompt('vultest')

  when 'report'
    unless vultest.nil?
      vultest.report
      vultest.attack_verify
    end

  else
    next
  end
end
