require_relative '../db'
require_relative '../utility'

module VultestReport

  def report(cve, vulenv_config_path)
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
    Utility.print_message('default', '  Affect system (CPE)')
    Utility.print_message('defalut', "  ==================")
    print "\n"
    cpe = DB.get_cpe(cve)
    cpe.each do |cpe_info|
      Utility.print_message('defalut', "    #{cpe_info}")
    end
    print "\n"

    # Verfiy target
    Utility.print_message('default', '  Verfiy target')
    Utility.print_message('defalut', "  ===============")
    print "\n"

    vulenv_config_detail = YAML.load_file(vulenv_config_path)
    Utility.print_message('default', "    #{vulenv_config_detail['os']['name']}:#{vulenv_config_detail['os']['version']}")
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
    print "\n"

    # Unique configure
    if vulenv_config_detail.key?('report')
      Utility.print_message('default', '  Unique configure')
      Utility.print_message('defalut', "  ================")
      msgs = vulenv_config_detail['report']
      msgs['msg'].each do |msg|
        Utility.print_message('defalut', "    #{msg}")
      end
      print "\n"
    end
  end

  module_function :report
end
