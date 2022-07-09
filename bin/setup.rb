#!/usr/bin/env ruby

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "tty-command"
  gem "tty-option"
end

module RailsVersionScope

  class Cli

    def initialize
      command = Command.new
      command.parse
      @options = command.run
    end

    def run
      Program.new(options).call
    end

    private

    attr_reader :options
  end

  class Command
    include TTY::Option

    usage do
      program "RailsVersionScope"

      command "run"

      desc "Prepare and run under specific Rails version"

      example "setup --rails-version=5.2.6"
    end

    flag :verbose do
      short "-v"
      long "--verbose"
      desc "Turn on output"
    end

    flag :help do
      short "-h"
      long "--help"
      desc "Print usage"
    end

    option :rails_version do
      required
      long "--rails-version string"
      desc "The version of Rails to use"
    end

    def run
      return params.to_h unless params[:help]

      print help
      exit
    end

  end

  class Program

    APP_ROOT    = File.expand_path("..", __dir__)
    PLUGIN_NAME = "ActiveStorageOverTime"
    PLUGIN_ROOT = File.expand_path("../#{PLUGIN_NAME}", __dir__)

    def initialize(options)
      @options = options
      @terminal = TTY::Command.new(printer: :pretty)
    end

    def call
      commands.each do |command, root_directory|
        run(command, root_directory)
      end
    end

    private

    attr_reader :terminal, :options

    def commands
      [
        ["rm -rf #{PLUGIN_NAME}", APP_ROOT],
        [create_rails_plugin, APP_ROOT],
        ["cp .ruby-version #{PLUGIN_ROOT}", APP_ROOT],
        ["BUNDLE_GEMFILE=../gemfiles/Gemfile.#{options[:rails_version]}.gemfile bundle exec rails generate model attachment", PLUGIN_ROOT],
        ["BUNDLE_GEMFILE=../gemfiles/Gemfile.#{options[:rails_version]}.gemfile bundle exec rails app:active_storage:install", PLUGIN_ROOT],
        # ["BUNDLE_GEMFILE=../gemfiles/Gemfile.#{options[:rails_version]}.gemfile bundle exec rails app:railties:install:migrations", PLUGIN_ROOT],
        ["BUNDLE_GEMFILE=../gemfiles/Gemfile.#{options[:rails_version]}.gemfile bundle exec rails db:migrate RAILS_ENV=test", PLUGIN_ROOT],
        ["cp tests/#{options[:rails_version]}/attachment_test.rb #{PLUGIN_NAME}/test/", APP_ROOT],
        ["cp tests/fixtures/blue.png #{PLUGIN_NAME}/test/fixtures/", APP_ROOT],
        ["./bin/dummy_setup add_asset_associated_to_attachment", APP_ROOT],
        ["BUNDLE_GEMFILE=../gemfiles/Gemfile.#{options[:rails_version]}.gemfile bundle exec rails test", PLUGIN_ROOT],
      ]
    end

    def run(cmd, root_directory)
      FileUtils.chdir root_directory do
        terminal.run(cmd, only_output_on_error: true)
      end
    end

    def create_rails_plugin
      base_options = [
        "--database=sqlite3",
        "--skip-yarn",
        "--skip-action-mailer",
        "--skip-puma",
        "--skip-action-cable",
        "--skip-sprockets",
        "--skip-spring",
        "--skip-listen",
        "--skip-coffee",
        "--skip-javascript",
        "--skip-turbolinks",
        "--skip-test" \
        "--skip-system-test",
        "--skip-bootsnap",
        "--no-rc",
      ]

      options = (base_options + extra_plugin_configuration).flatten.join(" ")

      "BUNDLE_GEMFILE=gemfiles/Gemfile.#{options[:rails_version]}.gemfile bundle exec "\
        "rails _#{options[:rails_version]}_ plugin new ActiveStorageOverTime --mountable #{options} --dummy-path=test/dummy"
    end

    def extra_plugin_configuration
      extra = []

      if Rails::VERSION::MAJOR == 6
        extra << [
          "--skip-collision-check",
          "--skip-git",
          "--skip-keeps",
          "--skip-active-job",
          "--skip-action-mailbox",
          "--skip-action-text",
          "--skip-active-job",
          "--skip-jbuilder",
        ]
      end

      if Rails::VERSION::MAJOR == 7
        extra << [
          "--skip-asset-pipeline",
          "--skip-hotwire",
        ]
      end

      extra.flatten
    end

  end

end

RailsVersionScope::Cli.new.run