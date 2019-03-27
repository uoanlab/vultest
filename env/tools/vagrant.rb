require 'fileutils'
require 'yaml'

module Vagrant

  def create(vulconfig_file, vulenv_dir)
    vulconfig = YAML.load_file(vulconfig_file)
    config = YAML.load_file('./config.yml')

    FileUtils.cp_r("./build/vagrant/#{vulconfig['construction']['os']['name']}/#{vulconfig['construction']['os']['version']}/Vagrantfile", "#{vulenv_dir}/Vagrantfile")
  end

  module_function :create

end
