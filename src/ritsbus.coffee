# Description:
#   立命館大学に関連する近江鉄道バスの時刻表通知
#
# Commands:
#   hubot bus <n分後> <S|P|か|笠|西> - to南草津駅from立命館
#   hubot kbus <n分後> - to草津駅from立命館
#   hubot rbus <n分後> <S|P|か|笠|西> - to立命館from草津駅
#
Buffer = require('buffer').Buffer
cron = require('cron').CronJob
request = require('request')
cheerio = require('cheerio')
iconv = require('iconv')
PublicHoliday = require('japanese-public-holiday')

SHOW_MAX_BUS = 7
viaShuttle = ["S", "直", "shuttle", "シャトル","直行"]
viaPanaEast = ["P", "パナ東"]
viaKagayaki = ["か", "かがやき"]
viaKasayama = ["笠", "笠山"]
viaPanaWest = ["西", "パナ西"]
viaList = [viaShuttle, viaPanaEast, viaKagayaki, viaKasayama, viaPanaWest]
allDay = ["ordinary", "saturday", "holiday"]
allDayName = ["平日", "土曜日", "日曜・祝日"]
urlToMinakusa = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=2&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2"]
urlToKusatsu = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=2&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1"]
urlToRitsumei = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1250&KaiKbn=NOW&pole=1", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?KaiKbn=NEXT&projCd=2&eigCd=7&pole=1&teiCd=1250", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1250&KaiKbn=NOW&pole=1"]

module.exports = (robot) ->
  # 毎日午前3時にその曜日の時刻表を取得し，データを更新する(エラー処理などはそのうち追加
  # TO DO : cronで叩くとなぜかエラーが出るのなんとかする
  # まあ最悪自分にリプライ投げるみたいな雑な対策でもいいかな
  new cron('0 3 * * *', () ->
    now = new Date
    console.log "午前3時:#{now}"
    # dayIndex = getDayOfWeek(now,robot)
    # getBusSchedule(allDay[dayIndex], urlToMinakusa[dayIndex], robot)
  ).start()

  # 立命館から南草津行き
  robot.respond /(bus|mbus|バス)(.*)/i, (msg) ->
    to = "minakusa"
    toName = "南草津"
    now = new Date
    options = msg.match[2].replace(/^\s+/,"").split(/\s/)

    # 何分後のバスを検索するか取得
    extensionMinutes = getExtensionMinutes(options)

    # バスの経由地判定
    viaBusStop = getViaBusStop(options)

    replyMessage = "\n#{toName}行き \n"
    replyMessage += getBusList(to, viaBusStop, extensionMinutes, now, robot)
    msg.reply replyMessage

  # 立命館から草津行き
  robot.respond /(kbus)(.*)/i, (msg) ->
    to = "kusatsu"
    toName = "草津"
    now = new Date
    options = msg.match[2].replace(/^\s+/,"").split(/\s/)

    # 何分後のバスを検索するか取得
    extensionMinutes = getExtensionMinutes(options)

    replyMessage = "\n#{toName}行き \n"
    replyMessage += getBusList(to, "", extensionMinutes, now, robot)
    msg.reply replyMessage

  # 南草津から立命館行き
  robot.respond /(rbus)(.*)/i, (msg) ->
    to = "ritsumei"
    toName = "立命館大学"
    now = new Date
    options = msg.match[2].replace(/^\s+/,"").split(/\s/)

    # 何分後のバスを検索するか取得
    extensionMinutes = getExtensionMinutes(options)

    # バスの経由地判定
    viaBusStop = getViaBusStop(options)

    replyMessage = "\n#{toName}行き \n"
    replyMessage += getBusList(to, viaBusStop, extensionMinutes, now, robot)
    msg.reply replyMessage


  # コマンドから全てのバスの時刻表を取得
  robot.respond /update/i, (msg) ->
    now = new Date
    for value,index in allDay
      getBusSchedule("minakusa", value, urlToMinakusa[index], robot)
      getBusSchedule("kusatsu", value, urlToKusatsu[index], robot)
      getBusSchedule("ritsumei", value, urlToRitsumei[index], robot)

# 何分後か判定
getExtensionMinutes = (options) ->
  #デフォルトは7分後からのバスを表示
  extensionMinutes = 7
  for opt in options
    if /\d+/.test(opt)
      extensionMinutes = parseInt(opt.match(/\d+/), 10)
  return extensionMinutes

# 経由地判定
getViaBusStop = (options) ->
  viaBusStop = ""
  for opt in options
    for via in viaList
      if opt in via
        viaBusStop = via[0]
  return viaBusStop

# バスの一覧文字列を返す
getBusList = (to, viaBusStop, extensionMinutes, date, robot) ->
  # 今の時間帯にextensionMinutes（デフォルトでは7）分後から
  dayIndex = getDayOfWeek(date, robot)
  afterDate = new Date(date.getTime() + extensionMinutes*60*1000)
  hour = afterDate.getHours()
  min = afterDate.getMinutes()
  if hour in [0..4]
    hour = 5
    min = 0
  busCounter = 0
  busHour = hour
  busList = ""
  # 3時間以内にあるバスを7件まで次のバスとして表示する
  while busCounter < SHOW_MAX_BUS and hour+3 > busHour
    nextBus = []
    key = "#{to}_#{allDay[dayIndex]}_time#{busHour}"
    while robot.brain.data[key] is null and busHour <= 24
      busHour++
      key = "#{to}_#{allDay[dayIndex]}_time#{busHour}"

    if busHour > 24
      busList += "最後のバスです"
      break

    for value, index in robot.brain.data[key]
      parseTime = parseInt(value.match(/\d{2}/))
      # シャトルバスの場合の判定
      if not parseBus = value.match(/\D/)
        parseBus = viaShuttle[0]
      # 現在の時刻より後のバスをnextBusに追加
      if (busHour > hour and ///#{viaBusStop}///.test(parseBus)) or (parseTime > min and ///#{viaBusStop}///.test(parseBus))
        nextBus.push(value)
        busCounter++
      if busCounter >= SHOW_MAX_BUS
        break

    busList += "#{busHour}時：#{nextBus.join()}\n"
    busHour++

  return busList

# 曜日の要素取得
getDayOfWeek = (now,robot) ->
  dayIndex = 0
  if PublicHoliday.isPublicHoliday(now) or now.getDay() is 0
    dayIndex = 2
  else if now.getDay() is 6
    dayIndex = 1
  return dayIndex

# 時刻表のbodyを取得する
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

# 時刻表のbodyからデータを加工し，hubotに記憶させる
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
