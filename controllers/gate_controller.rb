require './controllers/bot_controller'
require './models/user'
require './lib/authorizer'

class GatesController < BotController
  def initialize(bot)
    @gates = $config.gates
    $logger.debug @gates

    if @gates.nil?
      $logger.error "No gates configured"
      return
    end

    @supported_commands = ['gate', 'gate_open']

    super
  end

  def cmd_gate(message, text)
    return unless Authorizer.authorize(@bot, message)

    @bot.tg_bot.api.send_message(
      chat_id: message.chat.id,
      text: "Какой шлагбаум открыть?",
      reply_markup: JSON.generate({
        inline_keyboard: (1..@gates.count).map { |i| [{ text: "#{@gates[i - 1]['name']}", callback_data: "gate_open #{i}" }] }
      })
    )
  end

  def cmd_gate_open(message, text)
    if message.from.id != @bot.bot_info['id']
      reply message, "Это служебная команда, доступна только боту"
      return
    end

    @bot.tg_bot.api.delete_message(chat_id: message.chat.id, message_id: message.message_id)

    gate = text.split[1].to_i
    return unless gate > 0 && gate <= @gates.count

    if open_gate(gate)
      reply message, "Открываю шлагбаум №#{gate} (#{@gates[gate - 1]['name']})."
    else
      reply message, "Упс, что-то пошло не так, проверьте логи."
    end
  end

  private

  def open_gate(gate)
    system(@gates[gate - 1]['command'])
  end
end


