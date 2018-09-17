require_relative '../global/setting'
require_relative './create_env'

def create_vulenv_dir_module(cve, db)
  attack_vector_list = []
  vul_env_config_list = []
  attack_config_file_path_list = []

  cnt = 0
  db.execute('select * from configs where cve_name=?', "#{cve}") do |config|
    # create environment
    vulenv = CreateEnv.new("./#{config['config_path']}", "#{cnt}")
    vulenv.create_vagrantfile
    vulenv.create_ansible_dir
    vulenv.create_ansible_config
    vulenv.create_ansible_hosts
    vulenv.create_ansible_role
    vulenv.create_ansible_playbook
    attack_vector = vulenv.get_attack_vector

    attack_vector_list.push(attack_vector)
    vul_env_config_list.push([cnt, "./vultest/vulenv_#{cnt}"])
    attack_config_file_path_list.push(config['module_path'])

    cnt += 1
  end

  return attack_vector_list, vul_env_config_list, attack_config_file_path_list
end

def create_vulenv_module(id)
  puts "#{$execute_symbol} create vulnerability environment"
  Dir.chdir("./vultest/vulenv_#{id}") do
    start_up_spinner = TTY::Spinner.new("#{$parenthesis_symbol}:spinner#{$parenthesis_end_symbol} start up", success_mark: "#{$success_symbol}", error_mark: "#{$error_symbol}")
    start_up_spinner.auto_spin
    stdout, stderr, status = Open3.capture3('vagrant up')

    # when vagrant up is fail
    if status.exitstatus != 0 then
      reload_stdout, reload_stderr, reload_status = Open3.capture3('vagrant reload')
      if reload_status != 0 then
        start_up_spinner.error
        exit!
      end
    end

    reload_status, reload_stderr, reload_status = Open3.capture3('vagrant reload')
    if reload_status != 0 then
      start_up_spinner.error
      exit!
    end

    start_up_spinner.success
  end
end


