require 'open3'
require_relative '../ui'

module VulenvParams
  private

  def start_vulenv
    VultestUI.tty_spinner_begin('Start up')
    _stdout, _stderr, status = Open3.capture3('vagrant up')
    if status.exitstatus.zero?
      VultestUI.tty_spinner_end('success')
    else
      VultestUI.tty_spinner_end('error')
      reload_vulenv
    end
  end

  def reload_vulenv
    VultestUI.tty_spinner_begin('Reload')
    _stdout, _stderr, status = Open3.capture3('vagrant reload')
    if status.exitstatus.zero?
      VultestUI.tty_spinner_end('success')
    else
      VultestUI.tty_spinner_end('error')
    end
  end

  def hard_setup
    @vulenv_config['construction']['hard_setup']['msg'].each { |msg| VultestUI.print_vultest_message('caution', msg) }
    Open3.capture3('vagrant halt')

    puts('Please enter key when ready')
    gets
    start_vulenv
  end
end
