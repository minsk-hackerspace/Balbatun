require './models/user'

class Authorizer
  HACKERSPACE_BASE_URL = "https://hackerspace.by"
  def self.authorize(message)
    user = User.find_by(telegram_id: message.from&.id)

    unless user
      reply message, "Неизвестный пользователь. Пожалуйста, авторизуйтесь через кнопку в профиле пользователя на #{HACKERSPACE_BASE_URL}/profile"
      return nil
    end

    user
  end
end
