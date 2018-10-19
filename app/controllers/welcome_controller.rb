require 'faraday'
require 'json'
require 'date'

class WelcomeController < ApplicationController
  API_EP = "https://api.darksky.net/forecast/a7daf8b068803135c5f0b7eae0397955/"
  API_CITY_EP = "http://geoapi.heartrails.com/api/json"


  def index
    pref = 0
    File.open("/home/vagrant/weatherapp/public/pref.json") do |j|
      pref = JSON.load(j)
    end
    @pref_list = pref['marker'].map{|pr| pr['pref']}

    @pref = (@pref || params[:p]) || '埼玉県'
    @city = (@city || params[:c]) || '志木市'
    @coord = get_coord(@pref, @city)
    whole_data = get_data(*@coord)

    data = whole_data['daily']['data']
    @list = Array.new(7){|i| Hash.new}
    (0..6).each do |i|
      begin
        @list[i][:icon] = "/icon/#{data[i]['icon']}.png"
        @list[i][:prec] = "#{(data[i]['precipProbability']*100).to_f.round(1)}%"
        @list[i][:max] = "#{data[i]['temperatureHigh'].round(1)}℃"
        @list[i][:min] = "#{data[i]['temperatureLow'].round(1)}℃"
      rescue
        raise i.to_s + data[i].to_s
      end
    end

    data = whole_data['hourly']['data']
    @graph = Hash.new(8)
    (0..7).each do |i|
      @graph[Time.at(data[i*6]['time'].to_i).strftime("%d日 %H:00")] = data[i*6]['precipProbability'].round(1)
    end

    data = get_yest_data(*@coord)
    @yest = Hash.new
    @yest[:icon] = "/icon/#{data['icon']}.png"
    @yest[:max] = "#{data['temperatureHigh'].round(1)}℃"
    @yest[:min] = "#{data['temperatureLow'].round(1)}℃"

    render "welcome/index"
  end

  def red
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
    res = Faraday.get API_CITY_EP, {'method' => 'getTowns', 'city' => c}
    towns = JSON.parse(res.body)['response']
    lon = (towns['location'].map{|loc| loc['x'].to_f}.sum) / towns['location'].length
    lat = (towns['location'].map{|loc| loc['y'].to_f}.sum) / towns['location'].length
    return [lat, lon]
  end

  def get_data(lat, lon)
    res = Faraday.get "#{API_EP}#{lat},#{lon}", {'units' => 'si'}
    JSON.parse(res.body)
  end

  def get_yest_data(lat, lon)
    time_serial = Time.mktime(Time.now.year, Time.now.month, Time.now.day - 1).to_i
    res = Faraday.get "#{API_EP}#{lat},#{lon},#{time_serial.to_s}", {'units' => 'si', 'exclue' => 'hourly'}
    res = JSON.parse(res.body)['daily']['data']
    res.each do |rec|
      return rec if rec['time'].to_i == time_serial
    end
  end

end
