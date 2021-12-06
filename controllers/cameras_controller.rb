require './controllers/bot_controller'
require './models/user'
require './lib/authorizer'
require 'net/http'

class CamerasController < BotController
  def initialize(bot)
    @supported_commands = ['camera', 'cameras', 'camera_list']

    @cameras = $config.cameras

    super
  end

  def cmd_camera(message, text)
    return unless Authorizer.authorize(message)

    camera_id = text.split(' ', 2)[1]&.to_i || 0

    camera = @cameras[camera_id]

    unless camera
      reply message, "Камера не найдена"
      return
    end

    begin
      img = get_snapshot(camera)
    rescue => e
      $logger.error e.full_message
      reply message, e.message
    end

    reply_photo message, img, "Камера #{camera_id}: #{camera['name']}"
  end

  def cmd_camera_list(message, text)
    return unless Authorizer.authorize(message)

    reply message, "Камеры:\n#{@cameras.each_with_index.map{ |c, i| "#{i}: #{c['name']}"}.join(", \n")}"
  end

  def cmd_cameras(message, text)
    return unless Authorizer.authorize(message)

    reply message, "Минутку..."

    images_with_captions = []
    @cameras.each do |camera|
      begin
        image = get_snapshot(camera)
        images_with_captions << [image, "Камера: #{camera['name']}"]
      rescue
      end
    end
    reply_photos(message, images_with_captions)
  end

  private

  def get_snapshot(camera)
    uri = URI(camera['snapshot_uri'])

    req = Net::HTTP::Get.new(uri)
    req.basic_auth camera['user'], camera['password']

    res = Net::HTTP.start(uri.hostname, uri.port) { |http|
      http.request(req)
    }

    unless res.is_a? Net::HTTPSuccess
      raise "Не удалось получить изображение: #{res.code} #{res.message}"
    end

    res.body
  end
end
