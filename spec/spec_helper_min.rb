# encoding: utf-8
# This file provides a minimal Rails integration test environment with an empty database, without users.
require 'simplecov_helper'
require 'rspec_configuration'
require 'helpers/spec_helper_helpers'
require 'support/redis'
require 'helpers/named_maps_helper'

ENV['RAILS_ENV'] ||= 'test'
# INFO: this is the only slow step of the test boot process
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'profile/db'
require 'profile/witness'

Resque.inline = true

RSpec.configure do |config|
  config.include SpecHelperHelpers
  config.include NamedMapsHelper

  unless ENV['PARALLEL']
    config.before(:suite) do
      CartoDB::RedisTest.up
    end
  end

  config.before(:all) do
    unless ENV['PARALLEL']
      clean_redis_databases
      clean_metadata_database
      close_pool_connections
      drop_leaked_test_user_databases
    end

    if ENV['PROFILE']
      TestProfiler::Witness.create_witnesses
      TestProfiler::DB.initialize_profiler
    end
  end
  config.after(:all) do
    unless ENV['PARALLEL']
      close_pool_connections
      drop_leaked_test_user_databases
      delete_database_test_users
    end
  end

  unless ENV['PARALLEL']
    config.after(:suite) do
      CartoDB::RedisTest.down
    end
  end

  if ENV['PROFILE']
    config.after(:suite) do
      puts 'PROFILE OPS', TestProfiler::DB.operations
      TestProfiler::Witness.assert_witnesses_alive
    end
  end
end
