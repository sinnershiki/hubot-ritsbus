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
viaRitsumei = ["立"]
viaList = [viaShuttle, viaPanaEast, viaKagayaki, viaKasayama, viaPanaWest, viaRitsumei]
toList = ["minakusa", "kusatsu", "ritsumei"]
allDay = ["ordinary", "saturday", "holiday"]
allDayName = ["平日", "土曜日", "日曜・祝日"]
urlToMinakusa = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=2&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2"]
urlToKusatsu = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=2&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1"]
urlToRitsumei = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1250&KaiKbn=NOW&pole=1", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=2&eigCd=7&teicd=1250&KaiKbn=NOW&pole=1", "http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1250&KaiKbn=NOW&pole=1"]
urls = {
  "minakusa":
    urlToMinakusa
  "kusatsu":
    urlToKusatsu
  "ritsumei":
    urlToRitsumei
}

module.exports = (robot) ->
  # 毎日午前4時に時刻表データ自動更新
  new cron('1 4 * * *', () ->
    now = new Date
    console.log "自動更新:#{now}"
    try
      for day, index in allDay
        for to in toList
          brainBusSchedule(to, day, urls[to][index], robot)
    catch error
      console.log error
      envelope = room: 'Home'
      robot.send envelope, error.toString()
  ).start()

  # 立命館から南草津行き
  robot.respond /(bus|mbus|バス)(.*)/i, (msg) ->
    now = new Date
    to = toList[0] # "minakusa"
    toName = "南草津駅"
    options = msg.match[2].replace(/^\s+/,"").split(/\s/)

    # バスを検索する時間を指定
    searchDate = getSearchDate(now, options)
    # バスの経由地判定
    viaBusStop = getViaBusStop(options)

    replyMessage = "\n#{toName}行き(#{searchDate.getHours()}:#{searchDate.getMinutes()}以降のバス) \n"
    replyMessage += getBusList(to, viaBusStop, searchDate, robot)
    msg.reply replyMessage

  # 立命館から草津行き
  robot.respond /(kbus)(.*)/i, (msg) ->
    now = new Date
    to = toList[1] # "kusatsu"
    toName = "草津駅"
    options = msg.match[2].replace(/^\s+/,"").split(/\s/)

    # バスを検索する時間を指定
    searchDate = getSearchDate(now, options)

    replyMessage = "\n#{toName}行き(#{searchDate.getHours()}:#{searchDate.getMinutes()}以降のバス) \n"
    replyMessage += getBusList(to, "", searchDate, robot)
    msg.reply replyMessage

  # 南草津から立命館行き
  robot.respond /(rbus)(.*)/i, (msg) ->
    now = new Date
    to = toList[2] # "ritsumei"
    toName = "立命館大学"
    options = msg.match[2].replace(/^\s+/,"").split(/\s/)

    # バスを検索する時間を指定
    searchDate = getSearchDate(now, options)
    # バスの経由地判定
    viaBusStop = getViaBusStop(options)

    replyMessage = "\n#{toName}行き(#{searchDate.getHours()}:#{searchDate.getMinutes()}以降のバス) \n"
    replyMessage += getBusList(to, viaBusStop, searchDate, robot)
    msg.reply replyMessage

  # コマンドから全てのバスの時刻表を取得
  robot.respond /update/i, (msg) ->
    now = new Date
    for day, index in allDay
      for to in toList
        brainBusSchedule(to, day, urls[to][index], robot)

# 時刻表のbodyを取得する
brainBusSchedule = (to, day, url, robot) ->
  options =
    url: url
    timeout: 50000
    headers: {'user-agent': 'node title fetcher'}
    encoding: 'binary'
  request options, (error, response, body) ->
    conv = new iconv.Iconv('CP932', 'UTF-8//TRANSLIT//IGNORE')
    body = new Buffer(body, 'binary');
    body = conv.convert(body).toString();
    busSchedule = parseBody(to, day, body)
    for key, value of busSchedule
      robot.brain.data[key] = value
    robot.brain.save()

# 時刻表のbodyからデータを加工し，hubotに記憶させる
parseBody = (to, day, body) ->
  busSchedule = {}
  $ = cheerio.load(body)
  $('tr').each ->
    time = parseInt($(this).children('td').eq(0).find('b').text(), 10)
    if time in [5..24]
      bus = $(this).children('td').eq(1).find('a').text()
      bus = bus.match(/[P|か|笠|西|立]?\d{2}/g)
      key = "#{to}_#{day}_time#{time}"
      busSchedule[key] = bus
  return busSchedule

# コマンドのオプションから検索するバスの時間を返す
getSearchDate = (date, options) ->
  extensionMinutes = 7
  searchDate = new Date(date.getTime() + extensionMinutes*60*1000)
  for opt in options
    if extensionMinutes = opt.match(/^\d+$/)
      min = parseInt(extensionMinutes, 10)
      searchDate = new Date(date.getTime() + min*60*1000) if min <= 120
    if hhmm = opt.match(/\d+:\d+/)
      time = hhmm.toString().split(":")
      hour = parseInt(time[0], 10)
      minutes = parseInt(time[1], 10)
      hour = 24 if hour > 24
      minutes = 59 if minutes > 59
      searchDate.setHours(hour)
      searchDate.setMinutes(minutes)
      searchDate.setSeconds(0)
  return searchDate

# 経由地判定
getViaBusStop = (options) ->
  viaBusStop = ""
  for opt in options
    for via in viaList
      viaBusStop = via[0] if opt in via
  return viaBusStop

# バスの一覧文字列を返す
getBusList = (to, viaBusStop, searchDate, robot) ->
  dayIndex = getDayOfWeek(searchDate)
  hour = searchDate.getHours()
  min = searchDate.getMinutes()
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
      break if busCounter >= SHOW_MAX_BUS

    busList += "#{busHour}時：#{nextBus.join()}\n"
    busHour++
  return busList

# 曜日の要素取得
getDayOfWeek = (now) ->
  dayIndex = 0
  if PublicHoliday.isPublicHoliday(now) or now.getDay() is 0
    dayIndex = 2
  else if now.getDay() is 6
    dayIndex = 1
  return dayIndex
