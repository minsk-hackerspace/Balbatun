#!/usr/bin/ruby
# encoding: utf-8

require 'clockwork'
require 'clockwork/database_events'
require 'telegram/bot'
require './lib/configurator'
require './models/reminder'

$config = Configurator.new
$logger = $config.logger


token = $config.token

commands = {}
theBot = Telegram::Bot::Client.new(token, logger: $config.logger)


module Clockwork

  configure do |config|
    config[:sleep_timeout] = 5
    config[:logger] = $logger
    config[:tz] = $config.tz
    config[:max_threads] = 15
    config[:thread] = true
  end

  # required to enable database syncing support
  Clockwork.manager = DatabaseEvents::Manager.new

  sync_database_events model: Reminder, every: 1.minute do |r|
    theBot.api.send_message(chat_id: r.chat_id, text: r.text)
  end

  every 1.minute, '1min' do
    $logger.debug "1-min event"
  end
end
