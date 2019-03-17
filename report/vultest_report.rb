require_relative '../db'
require_relative '../utility'

module VultestReport

  def report(cve, vulenv_config_path, attack_config_path)
    Utility.print_message('default', 'vultest report')
    Utility.print_message('default', "==============")

    # Get CVE description
    cve_info = DB.get_cve_info(cve)
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
    Utility.print_message('default', '  Affect software version (CPE)')
    Utility.print_message('defalut', "  ==============================")
    print "\n"
    cpe = DB.get_cpe(cve)
    cpe.each do |cpe_info|
      Utility.print_message('defalut', "    #{cpe_info}")
    end
    print "\n"

    # Attack target host
    Utility.print_message('default', '  Attack target host')
    Utility.print_message('defalut', "  ===================")
    print "\n"

    vulenv_config_detail = YAML.load_file(vulenv_config_path)
    Utility.print_message('default', "    #{vulenv_config_detail['construction']['os']['name']}:#{vulenv_config_detail['construction']['os']['version']}")
=begin
    softwares = vulenv_config_detail['software']
    softwares.each do |software|
      if software.key?('version')
        Utility.print_message('default', "    #{software['name']}:#{software['version']}")
      else
        install_command = ''
        if software['os_depend']
          if vulenv_config_detail['os']['name'] == 'ubuntu'
            install_command = "apt-get install #{software['name']}"
          elsif vulenv_config_detail['os']['name'] == 'centos'
            install_command = "yum install #{software['name']}"
          end
          Utility.print_message('default', "    #{software['name']}:default(#{install_command})")
        else
          Utility.print_message('default', "    #{software['name']}:default")
        end
      end
    end
=end
    print "\n"

    # Configuration
    if vulenv_config_detail.key?('report')
      Utility.print_message('default', '  Configuration of attack target host')
      Utility.print_message('defalut', "  ===================================")
      print "\n"
      msgs = vulenv_config_detail['report']
      msgs['msg'].each do |msg|
        Utility.print_message('defalut', "    #{msg}")
      end
      print "\n"
    end

    attack_config_detail = YAML.load_file(attack_config_path)
    Utility.print_message('default', '  Attack method')
    Utility.print_message('defalut', "  ===============")
    print "\n"

    attack_methods = attack_config_detail['metasploit_module']
    attack_methods.each do |attack_method|
      Utility.print_message('default', "    module_name : #{attack_method['module_name']}")
      attack_method['options'].each do |option|
        Utility.print_message('default', "      #{option['name']} : #{option['var']}")
      end
      print "\n"
    end
  end

  module_function :report
end
