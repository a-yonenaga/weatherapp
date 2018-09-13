require 'faraday'
require 'json'
require 'date'

class WelcomeController < ApplicationController
  API_EP = "http://api.openweathermap.org/data/2.5/weather"
  API_KEY = "6327f39f74c32285bc13da99ea6c7193"

  def get_data(q, type = :weather)
    res = Faraday.get API_EP, {'q' => 'Tokyo', 'units' => 'metric', 'APPID' => API_KEY}
    JSON.parse(res.body)
  end

  def index
    @area = 'Tokyo'
    data = get_data(@area)

    @icon = "/icon/#{data['weather'][0]['icon']}.png"
    @temp_max = "#{data['main']['temp_max']}℃"
    @temp_min = "#{data['main']['temp_min']}℃"

    
    render "welcome/index"
  end

end
