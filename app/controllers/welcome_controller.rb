require 'faraday'
require 'json'
require 'date'

class WelcomeController < ApplicationController
  API_EP = "http://api.openweathermap.org/data/2.5/"
  API_KEY = "6327f39f74c32285bc13da99ea6c7193"

  @raw
  def get_data(q, type = :weather)
    #type := :weather or :forecast
    res = Faraday.get API_EP + type.to_s, {'q' => 'Tokyo', 'units' => 'metric', 'APPID' => API_KEY}
    @raw = res.body
    JSON.parse(res.body)
  end

  def index
    @area = 'Tokyo'
    data = get_data(@area, :weather)

    @icon = "/icon/#{data['weather'][0]['icon']}.png"
    @temp_max = "#{data['main']['temp_max']}℃"
    @temp_min = "#{data['main']['temp_min']}℃"

    @list = Array.new(5){|hash| hash = Hash.new}

    data = get_data(@area, :forecast)
    (0..4).each do |i|
      @list[i][:icon] = "/icon/#{data['list'][i*8]['weather'][0]['icon']}.png"
      @list[i][:temp_max] = "#{(0..7).map{|j| data['list'][i+j]['main']['temp_max'].to_f}.max}℃"
      @list[i][:temp_min] = "#{(0..7).map{|j| data['list'][i+j]['main']['temp_min'].to_f}.min}℃"
    end

    
    render "welcome/index"
  end

end
