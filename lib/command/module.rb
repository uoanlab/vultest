require_relative '../global/setting'

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


