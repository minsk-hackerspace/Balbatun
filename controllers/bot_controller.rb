class BotController
  attr_reader :supported_commands
  attr_reader :long_help

  def initialize(bot)
    @bot = bot

    @long_help = {} if @long_help.nil?
  end

  protected
  def reply(message, text)
    @bot.tg_bot.api.send_message(chat_id: message.chat.id, text: text)
  end
end
