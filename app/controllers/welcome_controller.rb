require 'faraday'
require 'json'
require 'date'

class WelcomeController < ApplicationController
  API_CITY_EP = "http://geoapi.heartrails.com/api/json"
  DEFAULT_PREF = "埼玉県"
  DEFAULT_CITY = "志木市"

  def index
    @pref_list = get_pref_list

    @pref = (@pref || params[:p]) || DEFAULT_PREF 
    @city = (@city || params[:c]) || DEFAULT_CITY
    @coord = get_coord(@pref, @city)

    bundle = DataFromAPI.new(*@coord)
    @daily = bundle.daily
    @hourly = bundle.hourly
    @yesterday = bundle.yesterday
    
    render "welcome/index"
  end

  def redirect
    lat = params[:lat].to_f
    lon = params[:lon].to_f
    res = Faraday.get API_CITY_EP, {'method' => 'searchByGeoLocation', 'x' => lon, 'y' => lat}
    towns = JSON.parse(res.body)['response']
    city = towns['location'].group_by{|loc| loc['city']}.sort{|a,b|a[1].length<=>b[1].length}.reverse[0][0]
    pref = towns['location'].group_by{|loc| loc['prefecture']}.sort{|a,b|a[1].length<=>b[1].length}.reverse[0][0]

    @pref = pref
    @city = city
    index
  end

  private
  def get_coord(p, c)
    # 域内の町丁の緯度経度を平均して、区域の緯度経度とする。
    res = Faraday.get API_CITY_EP, {'method' => 'getTowns', 'city' => c}
    towns = JSON.parse(res.body)['response']
    lon = (towns['location'].map{|loc| loc['x'].to_f}.sum) / towns['location'].length
    lat = (towns['location'].map{|loc| loc['y'].to_f}.sum) / towns['location'].length
    return [lat, lon]
  end

  def get_pref_list
    pref = 0
    File.open("/home/vagrant/weatherapp/public/pref.json") do |j|
      pref = JSON.load(j)
    end
    return pref['marker'].map{|pr| pr['pref']}
  end
end

class DailyData
  attr_reader :icon, :prec, :max, :min

  def initialize(json)
    @icon = "/icon/#{json['icon']}.png"
    @prec = "#{(json['precipProbability']*100).to_f.round(1)}%"
    @max = "#{json['temperatureHigh'].round(1)}℃"
    @min = "#{json['temperatureLow'].round(1)}℃"
  end
end

class HourlyData
  attr_reader :time, :prec

  def initialize(json)
    @time = Time.at(json['time'].to_i).strftime("%d日 %H:00")
    @prec = json['precipProbability'].round(1)
  end
end

class DataFromAPI
  API_EP = "https://api.darksky.net/forecast/a7daf8b068803135c5f0b7eae0397955/"
  CURRENT = 1
  YESTERDAY = 2
  attr_reader :daily, :hourly, :yesterday

  def initialize(lat, lon)
    whole_data = fetch_data(lat, lon)
    yesterday_data = fetch_data(lat, lon, YESTERDAY)
    json_daily = whole_data['daily']['data']
    json_hourly = whole_data['hourly']['data']

    @daily = (0..6).map{|i| DailyData.new(json_daily[i])}
    @hourly = (0..7).map{|i| HourlyData.new(json_hourly[i*6])}
    @yesterday = DailyData.new(yesterday_data)
  end

  private
  def fetch_data(lat, lon, mode = CURRENT)
    case mode
    when CURRENT
      return JSON.parse(Faraday.get("#{API_EP}#{lat},#{lon}", {'units' => 'si'}).body)
    when YESTERDAY
      time_serial = Time.mktime(Time.now.year, Time.now.month, Time.now.day - 1).to_i
      whole = Faraday.get "#{API_EP}#{lat},#{lon},#{time_serial.to_s}", {'units' => 'si', 'exclue' => 'hourly'}
      res = JSON.parse(whole.body)['daily']['data']
      res.each do |rec|
        return rec if rec['time'].to_i == time_serial
      end
    else
      raise
    end
  end
end

