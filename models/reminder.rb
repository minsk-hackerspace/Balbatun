require 'active_record'

class Reminder < ActiveRecord::Base

  def frequency
    0
  end

  def at
    time.to_s
  end
end
