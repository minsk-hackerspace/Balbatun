require './controllers/bot_controller'

class MiscController < BotController
  def initialize(bot)
    @supported_commands = ['help']
    super
  end

  def cmd_help(message, text)
    arg = text.split(/\s/)[1]&.downcase

    if arg then
      if arg == 'all' then
        text = "Help:\n"
        @bot.supported_commands.each do |cmd|
          next if cmd == 'help'

          text += "#{cmd} " + @bot.long_help(cmd) + "\n"
        end
      else
        if @bot.supported_commands.include?(arg) then
          text = "#{arg} " + @bot.long_help(arg)
        else
          text = "Command '#{arg}' not supported"
        end
      end
    else
      text = "Commands:\n"
      text += @bot.supported_commands.join ', '
    end

    reply(message, text)
  end
end
