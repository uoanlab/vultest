require_relative '../attack/exploit'
require_relative '../env/vulenv'
require_relative '../report/vultest_report'
require_relative '../utility'

module TestCommand
  def exploit(attack_machine_host, attack_config_path)
    if attack_config_path.nil? 
      Utility.print_message('error', 'Cannot search exploit configure')
      return nil
    end

    Exploit.exploit(attack_machine_host, attack_config_path)
  end

  def set(option, var)
    if option == 'attacker'
      Utility.print_message('caution', 'start up metasploit by kail linux')
      Utility.print_message('caution', "load msgrpc ServerHost=#{var} ServerPort=55553 User=msf Pass=metasploit")
    end

    return var
  end

  def report(cve, vulenv_config_path)
    if cve.nil?
      Utility.print_message('error', 'You have to set CVE.')
      return 'error'
    end

    if vulenv_config_path.nil?
      Utility.print_message('error', 'Cannot have vulnerable environmently configure')
    end

    VultestReport.report(cve, vulenv_config_path)
    Exploit.verify
  end

  def destroy
    Vulenv.destroy
  end

  module_function :exploit
  module_function :set
  module_function :report
  module_function :destroy
end
