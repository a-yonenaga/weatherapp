require 'faraday'
require 'json'
require 'date'

class WelcomeController < ApplicationController
  API_EP = "https://api.darksky.net/forecast/a7daf8b068803135c5f0b7eae0397955/"

  def get_data(lat, lon, type = :daily)
    res = Faraday.get "#{API_EP}#{lat},#{lon}", {'units' => 'si'}
    JSON.parse(res.body)[type.to_s]['data']
  end

  def get_yest_data(lat, lon)
    time_serial = Time.mktime(Time.now.year, Time.now.month, Time.now.day - 1).to_i
    res = Faraday.get "#{API_EP}#{lat},#{lon},#{time_serial.to_s}", {'units' => 'si'}
    res = JSON.parse(res.body)['daily']['data']
    res.each do |rec|
      return rec if rec['time'].to_i == time_serial
    end
  end

  def index
    @area = 'Tokyo'
    @point = [35.41, 139.41]
    data = get_data(*@point,:daily)

    @list = Array.new(7){|i| Hash.new}
    (0..6).each do |i|
      begin
        @list[i][:icon] = "/icon/#{data[i]['icon']}.png"
        @list[i][:prec] = "#{(data[i]['precipProbability']*100).to_f}%"
        @list[i][:max] = "#{data[i]['temperatureHigh']}℃"
        @list[i][:min] = "#{data[i]['temperatureLow']}℃"
      rescue
        raise i.to_s + data[i].to_s
      end
    end

    data = get_data(*@point, :hourly)
    @graph = Hash.new(8)
    (0..7).each do |i|
      @graph[Time.at(data[i*6]['time'].to_i).strftime("%d日 %H:00")] = data[i*6]['precipProbability']
    end

    data = get_yest_data(*@point)
    @yest = Hash.new
    @yest[:icon] = "/icon/#{data['icon']}.png"
    @yest[:max] = "#{data['temperatureHigh']}℃"
    @yest[:min] = "#{data['temperatureLow']}℃"

    render "welcome/index"
  end

end
