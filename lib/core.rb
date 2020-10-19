# Copyright [2020] [University of Aizu]
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
require 'tty-prompt'

require 'lib/select_vultest_case'
require 'lib/attack/core'
require 'lib/vulenv/core'
require 'lib/report/core'
require 'lib/print'

class Core
  attr_reader :vulenv, :attack, :test_case

  def initialize
    @vulenv = nil
    @attack = nil
    @test_case = nil
  end

  def select_vultest_case?(args)
    select_vultest_case = SelectVultestCase.new(
      cve: args[:cve]
    )
    return false if select_vultest_case.test_case_empty?

    @test_case = select_vultest_case.exec
    return false if test_case.nil?
    true
  end

  def create_vulenv?(args)
    @vulenv = Vulenv::Core.new(
      vulenv_dir: args[:vulenv_dir],
      test_case: test_case
    )

    return true if vulenv.create?

    false
  end

  def prepare_attack(args)
    @attack = Attack::Core.new(
      host: args[:attack_host],
      user: args[:attack_user],
      passwd: args[:attack_passwd],
      env_dir: args[:attack_env_dir],
      test_case: test_case
    )
  end

  def create_attack_env
    attack.create
  end

  def exec_attack
    attack.exec
  end

  def create_report(args)
    report = Report::Core.new(
      report_dir: args[:report_dir],
      vulenv: vulenv,
      attack: attack,
      test_case: test_case
    )

    report.create
    report.show
  end

  def destroy_env
    destroy_envs = TTY::Prompt.new.multi_select(
      'Please select the environment you want to delete',
      %w[vulenv attack_env]
    )

    destroy_envs.each do |env|
      case env
      when 'vulenv' then vulenv.destroy!
      when 'attack_env' then attack.destroy!
      end
    end
  end
end
