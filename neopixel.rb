require 'artoo'
require "pry"

connection :arduino, adaptor: :firmata, port: '/dev/cu.usbmodem1411'

device :led, driver: :led, pin: 14
device :matrix, driver: :neomatrix, pin: 15

work do
  loop do
    x = (rand * 5).to_i
    y = (rand * 8).to_i
    red = (rand * 200).to_int
    green = (rand * 200).to_int
    blue = (rand * 200).to_int
    matrix.on(x,y,red,green,blue)
    sleep 0.1
  end
end
