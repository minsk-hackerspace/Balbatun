require './controllers/bot_controller'
require './models/user'

class BramnikController < BotController
  def initialize(bot)
    @supported_commands = ['start']
    super
  end

  def cmd_start(message, text)
    token = text.split[1]

    user_id = nil

    if token
      user_id = auth_hs_user(token)
    else
      user = User.find_by!(telegram_id: message.from.id, chat_id: message.chat.id)
      user_id = user.hacker_id
    end

    if user_id
      tg_id = message.from.id
      chat_id = message.chat.id
      hacker = get_hs_user(user_id)

      user = User.find_or_create_by(telegram_id: tg_id, chat_id: chat_id, hacker_id: user_id) do |user|
        user.name = hacker[:name]
      end

      reply message, "Привет, #{user.name}! Я тебя знаю, ты член хакерспейса №#{user.hacker_id}."
    else
      reply message, "Пожалуйста, авторизуйтесь через кнопку в профиле пользователя на https://hackerspace.by/"
    end
  end

  private
  def auth_hs_user(token)
    #TODO

    user_id = nil

    if token == "verysecrettoken"
      user_id = 123
    end
    $logger.debug "Auth token is #{token}, return user id '#{user_id}'"

    user_id
  end

  def get_hs_user(user_id)
    #TODO

    {id: user_id, name: "Username"}
  end
end
