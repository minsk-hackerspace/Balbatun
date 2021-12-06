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

  def reply_photos(message, images_with_captions)
    photos = []
    upload_photos = {}

    images_with_captions.each_with_index { |item, i|
      image, caption = item[0], item[1]

      m = {
        type: 'photo',
        media: "attach://photo_#{i}",
        caption: caption
      }

      photos << m
      upload_photos["photo_#{i}"] = Faraday::UploadIO.new(StringIO.new(image), 'image/jpeg')
    }

    @bot.tg_bot.api.sendMediaGroup(
      {
        chat_id: message.chat.id,
        media: photos
      }.merge(upload_photos)
    )
  end
end
