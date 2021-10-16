
require './controllers/bot_controller'
require './models/reminder'

class ReminderController < BotController
  def initialize(bot)
    @supported_commands = ['remind', 'reminders', 'reminder_delete']

    @long_help = {
      'remind' => '<YYYY-MM-DD hh:mm> <text> — post text at given time',
      'reminders' => '— show the list of active reminders',
      'reminder_delete' => '<ID> — delete the reminder by ID'
    }

    super(bot)
  end

  def cmd_remind(message)
    message.text =~ /\/remind ([^\s]+\s[^\s]+)\s+(.*)$/
    $logger.debug "Parsed remind args: #{$1}, #{$2}"
    begin
      t = Time.parse $1
      text = $2
    rescue => e
      reply message, 'Неправильный формат времени, используйте YYYY-MM-DD hh:mm'
    end

    $logger.debug "Scheduling reminder for chat #{message.chat.id} at #{t} with text '#{text}'"
    r = Reminder.new(
      chat_id: message.chat.id,
      time: t,
      text: text
    )

    if r.save
      reply message, "Напоминание установлено, время #{r.time}"
    else
      reply message, "Что-то пошло не так :("
    end
  end

  def cmd_reminders(message)
    text = "Напоминания:\n"
    Reminder.where(chat_id: message.chat.id).each do |r|
      text += "#{r.id}. #{r.time}: #{r.text}\n"
    end

    reply message, text
  end

  def cmd_reminder_delete(message)
    args = message.text.split(' ')
    id = args[1].to_i

    if id == 0
      reply message, "Неправильный ID"
      return
    end

    r = Reminder.find(id)
    if r.nil?
      reply message, "Напоминание не найдено"
    else
      r.destroy
      reply message, "Напоминание №#{r.id} удалено"
    end
  end

end
