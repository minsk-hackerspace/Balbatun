require './controllers/bot_controller'
require './models/user'
require './lib/authorizer'
require 'net/http'

class BramnikController < BotController
  HACKERSPACE_BASE_URL = "https://hackerspace.by"
  EMIT_CODE_CMD = "ssh pi@bramnik.local sh -c \"'cd /srv/Bramnik/software/host && ./bramnik_mgr.py code emit _ID_ 10 BramnikBot _ID_'\""
  GET_NFC_KEY_COMMAND = "ssh pi@bramnik.local /srv/Bramnik/software/host/get_key.sh"

  def initialize(bot)
    @supported_commands = ['start', 'gen_code', 'read_card', 'whois', 'whoami', 'members_stats']
    super
  end

  def cmd_start(message, text)
    token = text.split[1]

    user_id = nil

    if token
      hs_user = auth_hs_user(token)
      user_id = hs_user['id'] if hs_user
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
      @bot.tg_bot.api.send_message(
        chat_id: message.chat.id,
        text: "Неизвестный пользователь. Пожалуйста, авторизуйтесь через кнопку «Авторизоваться у Брамника» в профиле пользователя на сайте хакерспейса",
        reply_markup: JSON.generate({
          inline_keyboard: [[
            { text: "Перейти в профиль", url: "#{HACKERSPACE_BASE_URL}/profile" }
          ]]
        })
      )
    end
  end

  def cmd_read_card(message, text)
    return unless Authorizer.authorize(@bot, message)

    reply message, "Приложите карту к считывателю..."

    key = `#{GET_NFC_KEY_COMMAND}`

    unless key.empty?
      key = "#{key[0..1]}:#{key[2..3]}:#{key[4..5]}:#{key[6..7]}"
      reply message, "Приложена карта. ID: #{key}"
    else
      reply message, "Карта не обнаружена"
    end

  end

  def cmd_gen_code(message, text)
    user = Authorizer.authorize(@bot, message)

    return unless user

    hs_user = get_hs_user(user.hacker_id)
    unless hs_user
      reply message, "Что-то пошло не так: не удалось получить информацию о пользователе с сайта хакерспейса"
      return
    end

    unless hs_user['access_allowed?']
      reply message, "Доступ в хакерспейс запрещён"
      return
    end

    code = bramnik_emit_code(user.hacker_id)

    if code
      reply message, "Код для открытия двери: #{code}, действует 10 минут"
    else
      reply message, "Упс! Сгенерировать код не удалось..."
    end
  end

  def cmd_whois(message, text)
    return unless Authorizer.authorize(@bot, message)

    arg = text.split(/\s/)[1]&.downcase
    uid = arg&.to_i

    unless uid
      reply message, "Формат команды: /whois <№ участника>"
      return
    end

    hs_user = get_hs_user(uid)
    unless hs_user
      reply message, "Участник №#{uid} не найден"
      return
    end

    reply message, "Участник №#{uid}: #{hs_user['first_name']} #{hs_user['last_name']}"
  end

  def cmd_whoami(message, text)
    user = Authorizer.authorize(@bot, message)

    unless user
      reply message, "Не авторизовано, используйте команду /start"
      return
    end

    unless user.hacker_id
      reply message, "Хм, вы не похожи на хакера"
    end

    reply message, "Участник №#{user.hacker_id}"
  end

  def cmd_members_stats(message, text)
    user = Authorizer.authorize(@bot, message)

    unless user
      reply message, "Не авторизовано, используйте команду /start"
      return
    end

    stats = get_hs_stats
    unless stats
      reply message, "Не удалось получить статистику с сайта"
      return
    end

    t = "Статистика участников:\n\n"
    t += "Всего участников: #{stats['members_count']}\n"
    t += "Активных участников: #{stats['active_members']}\n\n"

    t += "Количество активных пользователей по тарифам:\n"
    stats['tariff_stats'].values.each do |ts|
      t += "#{ts['users']}\t #{ts['name']} (#{ts['monthly_price']} руб./мес.)\n"
    end

    reply message, t
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

  def get_hs_stats
    res = query_hs("/bramnik/members_statistics")

    unless res.is_a?(Net::HTTPSuccess)
      $logger.warn "Failed to retrieve members statistics from the HS site: #{res.code} #{res.message}"
      return nil
    end

    JSON.parse(res.body)
  end

  def bramnik_emit_code(user_id)
    cmd = EMIT_CODE_CMD.gsub('_ID_', user_id.to_s)
    res = `#{cmd}`
    code = res&.split[3]
    code
  end
end
