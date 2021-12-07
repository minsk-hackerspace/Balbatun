#!/usr/bin/env ruby
# encoding: utf-8

require 'telegram/bot'
require 'net/http/persistent'
require './lib/configurator'

$config = Configurator.new
$logger = $config.logger

class TheBot
  attr_reader :tg_bot

  def initialize
    token = $config.token

    Telegram::Bot.configure do |config|
      config.adapter = :net_http_persistent
    end

    @tg_bot = Telegram::Bot::Client.new(token, logger: $config.logger)

    Dir.glob('./controllers/*_controller.rb').each do |file|
      $logger.debug("Loading #{file}")
      require file
    end

    @commands = {}
    @controllers = []

    c_classes = ObjectSpace.each_object(Class).select { |c| c < BotController }

    c_classes.each do |controller_class|
      next if !$config.controllers_enabled.include?(controller_class.name.delete_suffix('Controller'))
      c = controller_class.new(self)
      c.supported_commands.each { |cmd| @commands[cmd] = c }
      @controllers << c
    end

    $logger.debug "Controllers: " + @controllers.map { |c| c.class.name }.join(', ')
    $logger.debug "Commands: " + @commands.keys.join(', ')
  end

  def supported_commands
    @commands.keys
  end

  def long_help(command)
    h = @commands[command]&.long_help[command]
    if h.nil?
      h = "no help"
    end
    h
  end

  def run_loop
    @tg_bot.run do |bot|
      @me = bot.api.getMe['result']
      $logger.debug "Me: " + @me.inspect

      bot.listen do |message|
        begin
          next unless message.is_a? Telegram::Bot::Types::Message
          next if message.text.nil?

          text = message.text

          if message.chat.id < 0
            first, text = text.split(/[\s,]+/, 2)
            # Skip the message if not addressed for the bot
            next if not ['@' + @me['username'], @me['first_name']].include?(first)
          end

          $logger.debug "Msg: chat #{message.chat.id}, from '#{message.from&.id}'(@#{message.from&.username}): #{message.text || "<non-text"}"

          c = text.split(' ')[0].strip
          next if c.nil? or c == ''

          c.delete_prefix! '/'
          c.downcase!

          begin
            @commands[c]&.send("cmd_#{c}", message, text)
          rescue => e
            $logger.error "Command execution error:\n" + e.full_message
          end
        rescue => e
          $logger.error "Message handling error:\n" + e.full_message
        end
      end
    end
  end
end

theBot = TheBot.new
theBot.run_loop
