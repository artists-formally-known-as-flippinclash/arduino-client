require 'artoo'
require "pry"
require "faraday"
require "json"

connection :arduino, adaptor: :firmata, port: '/dev/cu.usbmodem1411'

device :button_red, driver: :button, pin: 2, interval: 0.01
device :button_yellow, driver: :button, pin: 3, interval: 0.01
device :button_blue, driver: :button, pin: 4, interval: 0.01
device :button_green, driver: :button, pin: 5, interval: 0.01
device :button_white, driver: :button, pin: 6, interval: 0.01
device :button_purple, driver: :button, pin: 7, interval: 0.01
device :matrix, driver: :neomatrix, pin: 15

LED = Struct.new(:x, :y)

FEEDBACK_LEDS = [
  LED.new(1,6),
  LED.new(1,7),
  LED.new(0,6),
  LED.new(0,7),
]

class Game
  ENTRY_MAP = {
    red: :alpha,
    yellow: :beta,
    blue: :gamma,
    green: :delta,
    white: :epsilon,
    purple: :zeta,
  }

  COLOR_MAP = {
    alpha: [255,0,0],
    beta: [255,255,0],
    gamma: [0,0,255],
    delta: [0,255,0],
    epsilon: [255,255,255],
    zeta: [255,0,255],
  }

  ENTRY_MAX = 4

  attr_reader :connection, :entry, :player_id, :match_id, :matrix

  def initialize(connection, matrix)
    @connection = connection
    @matrix = matrix
    @entry = []
  end

  def create_match
    response = connection.post("/matches", player: { name: "Arduino" })
    json = JSON.parse(response.body)
    @player_id = json.fetch("you").fetch("id")
    @match_id = json.fetch("data").fetch("id")
    puts "Starting match: #{json.fetch("data").fetch("name")}!"
    connection.post("/matches/#{match_id}/start")
  end

  def add_entry(entry_color)
    entry << ENTRY_MAP[entry_color]
    refresh_display
    if entry.count == ENTRY_MAX
      submit_entry
      @entry = []
      clear_display
    end
  end

  def submit_entry
    response = connection.post do |r|
      r.url "/matches/#{match_id}/players/#{player_id}/guesses"
      r.headers['Content-Type'] = 'application/json'
      r.body = { guess: { code_pegs: entry } }.to_json
    end
    json = JSON.parse(response.body)
    feedback = json.fetch("data").fetch("feedback")
    colors = { "position_count" => [255,0,0], "peg_count" => [255,255,255] }

    if json.fetch("data").fetch("outcome") == "correct"
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

    leds = FEEDBACK_LEDS.dup
    leds.each { |led| matrix.off(led.x, led.y); sleep 0.01 }
    feedback.fetch("position_count").times do
      led = leds.shift
      matrix.on(led.x, led.y, 255,0,0)
      sleep 0.01
    end
    feedback.fetch("peg_count").times do
      led = leds.shift
      matrix.on(led.x, led.y, 255,255,255)
      sleep 0.01
    end
  end

  def refresh_display
    entry.each_with_index do |entry_peg, index|
      5.times do |n|
        matrix.on(n,index,*COLOR_MAP[entry_peg])
        sleep 0.01
      end
    end
  end

  def clear_display
    4.times do |n|
      5.times do |m|
        matrix.off(m,n)
        sleep 0.01
      end
    end
  end
end

work do
  c = Faraday.new("http://api.blasterminds.com")
  #c = Faraday.new("http://localhost:9292")
  game = Game.new(c, matrix)

  on button_red, :push => proc { game.add_entry(:red) }
  on button_yellow, :push => proc { game.add_entry(:yellow) }
  on button_blue, :push => proc { game.add_entry(:blue) }
  on button_green, :push => proc { game.add_entry(:green) }
  on button_white, :push => proc { game.add_entry(:white) }
  on button_purple, :push => proc { game.add_entry(:purple) }

  game.create_match
end
