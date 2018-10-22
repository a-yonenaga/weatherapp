// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require turbolinks
//= require Chart.min
//= require jquery
//= require bootstrap-sprockets
//= require_tree .

$(function() {
  $('#p').change(function() {
    sl = document.getElementById('c');
    while(sl.lastChild){ sl.removeChild(sl.lastChild); }
    op = document.createElement("option");
    op.value = '未選択';
    op.text = '未選択';
    document.getElementById("c").appendChild(op);
    addCities();
  });

  $('#c').change(function() {
    if (c.value != '未選択') {window.location.href='./city,' + p.value + ',' + c.value;} 
  });

  $("#loc").click(function() {
    if ( navigator.geolocation ){
        navigator.geolocation.getCurrentPosition(
        function(position){
          coord = position.coords.latitude + ',' + position.coords.longitude;
          window.location.href='../coord,' + coord;
        },
        function(err){
          window.alert("位置情報が取得できませんでした。\n(" + err.code + "," + err.message + ")");
        },
        {
          "enableHighAccuracy": false,
          "timeout": 8000,
          "maximumAge": 2000
        }
      );
    } else {
      window.alert('位置情報が取得できないブラウザです。');
    }  
  });
});

function addCities(){
  $.getJSON('https://geoapi.heartrails.com/api/json?jsonp=?',
    {
      method: 'getCities',
      prefecture: p.value
    }
  )
  .done(function(data) {
    if (data.response) {
      var result = data.response.location;
      for(var i=0;i<result.length;i++){
        let op = document.createElement("option");
        op.value= result[i].city;
        op.text = result[i].city;
        document.getElementById("c").appendChild(op);
      }
    } else {
      window.alert("APIの接続に失敗しました。");
    }
  });
}

