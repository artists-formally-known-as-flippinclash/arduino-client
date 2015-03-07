require 'artoo'
require "pry"

connection :arduino, adaptor: :firmata, port: '/dev/cu.usbmodem1411'

class ComboLED
  attr_reader :leds

  def initialize(*leds)
    @leds = leds
  end

  def on
    leds.each(&:on)
  end

  def off
    leds.each(&:off)
  end
end

device :red, driver: :led, pin: 14
device :yellow, driver: :led, pin: 2
device :blue, driver: :led, pin: 3
device :green, driver: :led, pin: 4
device :white, driver: :led, pin: 5
device :purple_blue, driver: :led, pin: 6
device :purple_red, driver: :led, pin: 7
#purple = ComboLED.new(purple_blue, purple_red)

device :button_red, driver: :button, pin: 8, interval: 0.01
device :button_yellow, driver: :button, pin: 9, interval: 0.01
device :button_blue, driver: :button, pin: 10, interval: 0.01
device :button_green, driver: :button, pin: 11, interval: 0.01
device :button_white, driver: :button, pin: 12, interval: 0.01
device :button_purple, driver: :button, pin: 13, interval: 0.01

work do
  binding.pry
  purple = ComboLED.new(purple_blue, purple_red)

  on button_red, :push    => proc { red.on }
  on button_red, :release => proc { red.off }

  on button_yellow, :push    => proc { yellow.on }
  on button_yellow, :release => proc { yellow.off }

  on button_blue, :push    => proc { blue.on }
  on button_blue, :release => proc { blue.off }

  on button_green, :push    => proc { green.on }
  on button_green, :release => proc { green.off }

  on button_white, :push    => proc { white.on }
  on button_white, :release => proc { white.off }

  on button_purple, :push    => proc { purple.on }
  on button_purple, :release => proc { purple.off }
end
