# Copyright [2019] [University of Aizu]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'bundler/setup'
require 'fileutils'
require 'open3'
require 'tty-table'
require 'tty-prompt'

class Vagrant
  def initialize(args = {})
    @env_dir = args[:env_dir]
    @os_name = args[:os_name]
    @os_version = args[:os_version]
  end

  def create
    if @os_name == 'windows' || TTY::Prompt.new.yes?('Do you select a vagrant image in local?')
      puts('Please you select a vagrant image below:')
      puts("  OS name: #{@os_name}")
      puts("  OS version: #{@os_version}")
      box = select_vagrant_image_in_local

      create_base_vagrantfile(box)
      return unless @os_name == 'windows'

      Dir.chdir(@env_dir) do
        Open3.capture3('wget https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1')
      end
    elsif File.exist?("./lib/vulenv/tools/data/vagrant/#{@os_name}/#{@os_version}/Vagrantfile")
      FileUtils.cp_r("./lib/vulenv/tools/data/vagrant/#{@os_name}/#{@os_version}/Vagrantfile", "#{@env_dir}/Vagrantfile")
    end
  end

  private

  def create_table_of_vagrant
    table_index = 1
    table = []

    stdout, _stderr, _status = Open3.capture3('vagrant box list')
    stdout = stdout.split("\n")

    stdout.each do |box|
      array = box.delete('(').delete(')').split(' ')

      table.push([table_index, array[0], array[2]])
      table_index += 1
    end
    box_list = table.dup

    puts('Vagrant box list in your machine')
    header = ['id', 'box name', 'box version']
    table = TTY::Table.new(header, table)
    table.render(:ascii).each_line do |line|
      puts line.chomp
    end

    box_list
  end

  def select_vagrant_image_in_local
    box_list = create_table_of_vagrant
    list = []
    box_list.each { |b| list << "#{b[1]}:#{b[2]}" }

    message = 'Select an id for testing vagrant image?'
    select_box = TTY::Prompt.new.enum_select(message, list)

    { box_name: select_box.split(':')[0], box_version: select_box.split(':')[1] }
  end

  def create_base_vagrantfile(args = {})
    File.open("#{@env_dir}/Vagrantfile", 'w') do |file|
      file.puts("# -*- mode: ruby -*-\n")
      file.puts("# vi: set ft=ruby :\n\n")
      file.puts("Vagrant.configure(2) do |config|\n")
      file.puts("  config.vm.box = '#{args[:box_name]}'\n")
      file.puts("  config.vm.box_version = '#{args[:box_version]}'\n\n") if args.key?(:box_version)

      if @os_name == 'windows' then detail_vagrantfile_of_windows(file)
      else detail_vagrantfile_of_linux(file)
      end

      file.puts("    ansible.playbook = './ansible/playbook/main.yml'\n")
      file.puts("    ansible.inventory_path = './ansible/hosts/hosts.yml'\n")
      file.puts("    ansible.limit = 'vagrant'\n")
      file.puts("  end\n\n")
      file.puts('end')
    end
  end

  def detail_vagrantfile_of_windows(file)
    file.puts("  config.vm.guest = :windows\n  config.vm.communicator = 'winrm'\n  config.winrm.username = 'vagrant'\n")
    file.puts("  config.winrm.password = 'vagrant'\n  config.winrm.retry_limit = 30\n\n")

    file.puts("  config.vm.network 'private_network', ip: '192.168.177.177'\n")
    file.puts("  config.vm.network :forwarded_port, guest: 3389, host: 13_389\n")
    file.puts("  config.vm.network :forwarded_port, guest: 5985, host: 15_985, id: 'winrm', auto_correct: true\n\n")

    file.puts("  config.vm.provider 'virtualbox' do |vb|\n    vb.gui = true\n  end\n\n")

    file.puts("  config.vm.provision 'shell' do |shell|\n    shell.path = 'ConfigureRemotingForAnsible.ps1'\n  end\n\n")

    file.puts("  config.vm.provision 'ansible', run: 'always' do |ansible|\n")
  end

  def detail_vagrantfile_of_linux(file)
    file.puts("  config.vm.network 'private_network', ip: '192.168.177.177'\n")
    file.puts("  config.vm.network 'forwarded_port', guest: 80, host: 65_434\n")

    file.puts("  config.vm.provision 'shell', inline: <<-SHELL\n    yum update nss -y\n  SHELL") if @os_name.scan(/CentOS/i)

    file.puts("  config.vm.provision 'ansible_local', run: 'always' do |ansible|\n")
  end
end
