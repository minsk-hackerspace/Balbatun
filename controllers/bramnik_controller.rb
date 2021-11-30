require './controllers/bot_controller'
require './models/user'
require 'net/http'

class BramnikController < BotController
  HACKERSPACE_BASE_URL = "https://hackerspace.by"
  OPEN_THE_DOOR_CMD = "ssh pi@bramnik.local sudo systemctl kill -s USR1 bramnik"

  def initialize(bot)
    @supported_commands = ['start', 'open_door']
    super
  end

  def cmd_start(message, text)
    token = text.split[1]

    user_id = nil

    if token
      user_id = auth_hs_user(token)['id']
    else
      user = User.find_by(telegram_id: message.from.id, chat_id: message.chat.id)
      user_id = user&.hacker_id
    end

    if user_id
      tg_id = message.from.id
      chat_id = message.chat.id
      hacker = get_hs_user(user_id)

      user = User.find_or_create_by(telegram_id: tg_id)  do |user|
        user.name = hacker['first_name']
        user.chat_id = chat_id
        user.hacker_id = user_id
      end

      reply message, "Привет, #{user.name}! Я тебя знаю, ты член хакерспейса №#{user.hacker_id}."
    else
      reply message, "Неизвестный пользователь. Пожалуйста, авторизуйтесь через кнопку в профиле пользователя на #{HACKERSPACE_BASE_URL}/profile"
    end
  end

  def cmd_open_door(message, text)
    user = authorize!(message)

    return unless user

    hs_user = get_hs_user(user.hacker_id)
    unless hs_user
      reply message, "Что-то пошло не так: не удалось получить информацию о пользователе с сайта хакерспейса"
      return
    end

    $logger.debug hs_user.inspect
    unless hs_user['access_allowed?']
      reply message, "Доступ в хакерспейс запрещён"
      return
    end

    opened = open_the_door if hs_user['access_allowed?']

    if opened
      reply message, "Дверь открыта"
    else
      reply message, "Упс! Дверь открыть не удалось..."
    end
  end

  private
  def query_hs(path)
    uri = URI(HACKERSPACE_BASE_URL + path)
    res = Net::HTTP.get_response(uri, { "Authorization" => "Bearer #{$config.bramnik_token}" })

    res
  end

  def auth_hs_user(token)
    user_id = nil

    res = query_hs("/bramnik/find_user?auth_token=#{token}")

    unless res.is_a?(Net::HTTPSuccess)
      $logger.warn "Failed to retrieve user info from the HS site: #{res.code} #{res.message}"
      return nil
    end

    JSON.parse(res.body)
  end

  def get_hs_user(user_id)
    res = query_hs("/bramnik/find_user?id=#{user_id}")

    unless res.is_a?(Net::HTTPSuccess)
      $logger.warn "Failed to retrieve user info from the HS site: #{res.code} #{res.message}"
      return nil
    end

    JSON.parse(res.body)
  end

  def authorize!(message)
    user = User.find_by(telegram_id: message.from&.id)

    unless user
      reply message, "Неизвестный пользователь. Пожалуйста, авторизуйтесь через кнопку в профиле пользователя на #{HACKERSPACE_BASE_URL}/profile"
      return nil
    end

    user
  end

  def open_the_door
    system(OPEN_THE_DOOR_CMD, exception: false)
  end
end
