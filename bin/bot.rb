#!/usr/bin/env ruby
# encoding: utf-8

require 'telegram/bot'
require 'net/http/persistent'
require 'faraday/net_http_persistent'
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

  def bot_info
    @me
  end

  def run_loop
    @tg_bot.run do |bot|
      @me = bot.api.getMe['result'].freeze
      $logger.debug "Me: " + @me.inspect

      bot.listen do |message|
        begin
          $logger.debug message.inspect

          case message.class.to_s
          when 'Telegram::Bot::Types::Message'
            cmd, message, text = parse_message(message)
          when 'Telegram::Bot::Types::CallbackQuery'
            cmd, message, text = parse_callback(message)
          else
            next
          end

          next if cmd.nil?

          $logger.debug "Command #{cmd}, text: #{text}"

          begin
            # text is command arguments with command name
            @commands[cmd]&.send("cmd_#{cmd}", message, text)
          rescue => e
            $logger.error "Command execution error:\n" + e.full_message
          end
        rescue => e
          $logger.error "Message handling error:\n" + e.full_message
        end
      end
    end
  end

  private

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

  def entity_text(message, entity)
    return nil unless entity

    message&.text[entity.offset..(entity.offset + entity.length)]
  end

  def check_for_group_command(message)
    entity = message.entities.first

    return nil unless entity&.type == "bot_command"
    return nil unless entity.is_a? Telegram::Bot::Types::MessageEntity

    command = entity_text(message, entity).chomp(' ')
    command, nick = command.split('@')

    $logger.debug "Command, nick: #{command.inspect}, #{nick.inspect}"

    return nick == @me["username"] ? command : nil
  end

  def parse_message(message)
    return nil if message.text.nil?

    text = message.text
    command = nil

    if message.chat.id < 0
      command = check_for_group_command(message)

      $logger.debug "Command: " + command.inspect

      unless command
        first, text = text.split(/[\s,]+/, 2)
        # Skip the message if not addressed for the bot
        return nil if not ['@' + @me['username'], @me['first_name']].include?(first)
      end
    end

    $logger.debug "Msg: chat #{message.chat.id}, from '#{message.from&.id}'(@#{message.from&.username}): #{message.text || "<non-text"}"

    return nil if command.nil? && text.nil?

    c = command || text.split(' ')[0].strip
    return nil if c.nil? or c == ''

    c.delete_prefix! '/'
    c.downcase!

    return c, message, text
  end

  def parse_callback(callback)
    text = callback.data
    cmd = text.split(' ')[0]

    return cmd, callback.message, text
  end
end

theBot = TheBot.new
theBot.run_loop
