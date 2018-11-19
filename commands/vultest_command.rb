require_relative '../attack/exploit'
require_relative '../env/vulenv'
require_relative '../utility'

module VultestCommand
  def test(cve)
    vulenv_config_path, attack_config_path = Vulenv.select(cve)

    if vulenv_config_path.nil? || attack_config_path.nil?
      Utility.print_message('error', 'Cannot test vulnerability')
      return nil, nil
    end

    if Vulenv.create(vulenv_config_path) == 'error'
      Utility.print_message('error', 'Cannot start up vulnerable environment')
      return nil, nil
    end

    Exploit.prepare(vulenv_config_path)

    return vulenv_config_path, attack_config_path
  end

  def exit
    return 'success'
  end

  module_function :test
  module_function :exit
end
