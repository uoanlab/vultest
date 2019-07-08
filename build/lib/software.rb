module AssistSoftware
  private

  def select_method(software, software_ansible_dir, method)
    case method
    when 'apt' then method_apt(software, software_ansible_dir)
    when 'yum' then method_yum(software, software_ansible_dir)
    when 'gem' then method_gem(software, software_ansible_dir)
    when 'source' then method_source(software, software_ansible_dir)
    end
  end

  def method_apt(software, software_ansible_dir)
    FileUtils.mkdir_p("#{software_ansible_dir}/#{software['name']}/tasks")
    FileUtils.cp_r('./build/ansible/roles/apt/tasks/main.yml', "#{software_ansible_dir}/#{software['name']}/tasks/main.yml")

    FileUtils.mkdir_p("#{software_ansible_dir}/#{software['name']}/vars")
    File.open("#{software_ansible_dir}/#{software['name']}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      vars_file.puts("name_and_version: #{software['name']}=#{software['version']}")
    end
  end

  def method_yum(software, software_ansible_dir)
    FileUtils.mkdir_p("#{software_ansible_dir}/#{software['name']}/tasks")
    FileUtils.cp_r('./build/ansible/roles/yum/tasks/main.yml', "#{software_ansible_dir}/#{software['name']}/tasks/main.yml")

    FileUtils.mkdir_p("#{software_ansible_dir}/#{software['name']}/vars")
    File.open("#{software_ansible_dir}/#{software['name']}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      vars_file.puts("name_and_version: #{software['name']}-#{software['version']}")
    end
  end

  def method_gem(software, software_ansible_dir)
    FileUtils.mkdir_p("#{software_ansible_dir}/#{software['name']}/tasks")
    FileUtils.cp_r(
      './build/ansible/roles/gem/tasks/main.yml',
      "#{software_ansible_dir}/#{software['name']}/tasks/main.yml"
    )

    FileUtils.mkdir_p("#{software_ansible_dir}/#{software['name']}/vars")
    File.open("#{software_ansible_dir}/#{software['name']}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')
      vars_file.puts("name: #{software['name']}")
      vars_file.puts("version: #{software['version']}")
      option_user(vars_file, software)
    end
  end

  def method_source(software, software_ansible_dir)
    FileUtils.mkdir_p("#{software_ansible_dir}/#{software['name']}/tasks")
    FileUtils.cp_r(
      "./build/ansible/roles/source/#{software['name']}/tasks/main.yml",
      "#{software_ansible_dir}/#{software['name']}/tasks/main.yml"
    )

    FileUtils.mkdir_p("#{software_ansible_dir}/#{software['name']}/vars")
    File.open("#{software_ansible_dir}/#{software['name']}/vars/main.yml", 'w') do |vars_file|
      vars_file.puts('---')

      if software['name'] == 'bash' then source_bash(vars_file, software)
      else vars_file.puts("version: #{software['version']}")
      end

      option_configure_command(vars_file, software)
      option_src_dir(vars_file, software)
      option_user(vars_file, software)
    end
  end

  def source_bash(vars_file, software)
    version = software['version'].split('.')
    vars_file.puts("version: #{version[0] + '.' + version[1]}")
    vars_file.puts('patches:')
    version[2].to_i.times do |index|
      index += 1
      if index.to_i < 10
        vars_file.puts("   - {name: patch-#{index}, version: bash#{version[0]}#{version[1]}-00#{index}}")
      elsif (index.to_i >= 10) && (index.to_i < 100)
        vars_file.puts("   - {name: patch-#{index}, version: bash#{version[0]}#{version[1]}-0#{index}}")
      else
        vars_file.puts("   - {name: patch-#{index}, version: bash#{version[0]}#{version[1]}-#{index}}")
      end
    end
  end

  def option_configure_command(vars_file, software)
    if software.key?('configure_command')
      vars_file.puts("configure_command: #{software['configure_command']}")
    else
      vars_file.puts('configure_command: ./configure')
    end
  end

  def option_src_dir(vars_file, software)
    if software.key?('src_dir')
      vars_file.puts("src_dir: #{software['src_dir']}")
    else
      vars_file.puts('src_dir: /usr/local/src')
    end
  end

  def option_user(vars_file, software)
    if software.key?('user') && !software['user'].nil?
      vars_file.puts("user: #{software['user']}\nuser_dir: /home/#{software['user']}")
    else
      vars_file.puts("user: test\nuser_dir: /home/test")
    end
  end
end
