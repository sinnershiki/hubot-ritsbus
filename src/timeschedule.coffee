# Description:
#   近江鉄道バスfrom立命館to南草津(or草津)の時刻表取得＆パース
#
# Commands:
#   hubot data update
#
Buffer = require('buffer').Buffer
cron = require('cron').CronJob
request = require('request')
cheerio = require('cheerio')
iconv = require('iconv')

allDay = ["ordinary", "saturday", "holiday"]
allDayName = ["平日", "土曜日", "日曜・祝日"]
urlMinakusa = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=2&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2"]
urlKusatsu = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=2&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1"]

module.exports = (robot) ->
  #毎日午前3時にその曜日の時刻表を取得し，データを更新する(エラー処理などはそのうち追加
  # TO DO : cronで叩くとなぜかエラーが出るのなんとかする
  # まあ最悪自分にリプライ投げるみたいな雑な対策でもいいかな
  new cron('0 3 * * *', () ->
    now = new Date
    console.log "午前3時:#{now}"
    #dayIndex = getDayOfWeek(now,robot)
    #getBusSchedule(allDay[dayIndex], url[dayIndex], robot)
  ).start()

  #コマンドから全てのバスの時刻表を取得
  robot.respond /data update/i, (msg) ->
    now = new Date
    for value,index in allDay
      getBusSchedule("minakusa",value,urlMinakusa[index],robot)
      getBusSchedule("kusatsu",value,urlKusatsu[index],robot)

#時刻表のbodyを取得する
getBusSchedule = (to,day,url,robot) ->
  options =
  url: url
  timeout: 50000
  headers: {'user-agent': 'node title fetcher'}
  encoding: 'binary'
  request options, (error, response, body) ->
    conv = new iconv.Iconv('CP932', 'UTF-8//TRANSLIT//IGNORE')
    body = new Buffer(body, 'binary');
    body = conv.convert(body).toString();
    brainSchedule(to,day,body,robot)

#時刻表のbodyからデータを加工し，hubotに記憶させる
brainSchedule = (to,day,body,robot) ->
  $ = cheerio.load(body)
  console.log "#{to}_#{day} 開始"
  $('tr').each ->
    time = parseInt($(this).children('td').eq(0).find('b').text(),10)
    if time in [5..24]
      a = $(this).children('td').eq(0).find('b').text()
      b = $(this).children('td').eq(1).find('a').text()
      bm = b.match(/[P|か|笠|西]?\d{2}/g)
      key = "#{to}_#{day}_time#{time}"
      robot.brain.data[key] = bm
      robot.brain.save()
    console.log "#{to}_#{day} 完了"
