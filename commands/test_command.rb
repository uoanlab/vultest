require_relative '../attack/exploit'
require_relative '../env/vulenv'
require_relative '../report/vultest_report'
require_relative '../utility'

module TestCommand
  def exploit(attack_machine_host, vulenv_config_path, attack_config_path)
    if attack_config_path.nil? 
      Utility.print_message('error', 'Cannot search exploit configure')
      return nil
    end

    Exploit.exploit(attack_machine_host, vulenv_config_path, attack_config_path)
  end

  def set(option, var)
    if option == 'ATTACKER'
      Utility.print_message('caution', 'start up metasploit on kail linux')
      Utility.print_message('caution', "load msgrpc ServerHost=#{var} ServerPort=55553 User=msf Pass=metasploit")
      return var
    end

    if option == 'TESTDIR'
      path = ''
      path_elm = var.split("/")

      path_elm.each do |elm|
        path.concat('/') unless path.empty?
        if elm[0] == '$'
          elm.slice!(0)
          if ENV.key?(elm)
            path.concat(ENV[elm])
          else
            path.concat(elm)
          end
        else
          path.concat(elm)
        end
      end

      return path
    end
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

  def destroy(vulenv_dir)
    Vulenv.destroy(vulenv_dir)
  end

  module_function :exploit
  module_function :set
  module_function :report
  module_function :destroy
end
