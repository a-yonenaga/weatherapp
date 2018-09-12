require 'faraday'
require 'json'

class WelcomeController < ApplicationController
  API_EP = "http://api.openweathermap.org/data/2.5/weather"
  API_KEY = "6327f39f74c32285bc13da99ea6c7193"

  def get_data(q, type = :weather)
    res = Faraday.get API_EP, {'q' => 'Tokyo', 'units' => 'metric', 'APPID' => API_KEY}
    JSON.parse(res.body)
    #@a = result['weather'][0]['main']
  end

  def index
    data = get_data('Tokyo')
    @icon = "/icon/#{data['weather'][0]['icon']}.png"
    @temp_max = "#{data['main']['temp_max']}℃"
    @temp_min = "#{data['main']['temp_min']}℃"
    #@rain = data['rain']['3h']
    render "welcome/index"
  end

  def hello
    render text: 'Hello!'
  end

  def bye
    render :text => 'Bye!'
  end

end
