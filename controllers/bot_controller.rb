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

  def reply_photo(message, image, caption)
    @bot.tg_bot.api.send_photo(
      chat_id: message.chat.id,
      caption: caption,
      photo: Faraday::UploadIO.new(StringIO.new(image), 'image/jpeg')
    )
  end
end
