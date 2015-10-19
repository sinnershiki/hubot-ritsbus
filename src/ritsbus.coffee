# Description:
#   近江鉄道バスfrom立命館to南草津(or草津)の時刻表通知
#
# Commands:
#   hubot bus <n分後> <シャトル|P|かがやき|笠山|パナ西|草津> - 経由地
#
cron = require('cron').CronJob
PublicHoliday = require('japanese-public-holiday')

SHOW_MAX_BUS = 7
viaS = ["S", "直", "shuttle", "シャトル","直行"]
viaP = ["P", "パナ東"]
viaC = ["か", "かがやき"]
viaK = ["笠", "笠山"]
viaN = ["西", "パナ西"]
allDay = ["ordinary", "saturday", "holiday"]
allDayName = ["平日", "土曜日", "日曜・祝日"]

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

  #次のバスを表示（デフォルトでは10分後）
  robot.respond /bus(.*)/i, (msg) ->
    now = new Date
    dayIndex = getDayOfWeek(now,robot)
    option = msg.match[1].replace(/^\s+/,"").split(/\s/)
    nextTime = parseInt(option[0],10)
    bus = ""
    kind = ""
    to = "minakusa"
    #一つ目の引数が数字でないまたは空の場合
    #10分後以降を検索することを設定し，一つ目の引数からバスの行き先を判定
    if isNaN(nextTime)
      nextTime = 7
      kind = option[0]
      #一つ目の引数が数字である場合，2つ目の引数から行き先を判定
    else
      kind = option[1]
      #バスの行き先判定
      toName = "南草津"
    if kind in viaS
      bus = "直"
    else if kind in viaP
      bus = "P"
    else if kind in viaC
      bus = "か"
    else if kind in viaK
      bus = "笠"
    else if kind in viaN
      bus = "西"
    else if /^草津*/.test(kind)
      to  = "kusatsu"
      toName = "草津"
    #今の時間帯にnextTime（デフォルトでは7）分後から3時間以内にあるバスを
    #7件まで次のバスとして表示する
    afterDate = new Date(now.getTime() + nextTime*60*1000)
    hour = afterDate.getHours()
    min = afterDate.getMinutes()
    if hour in [0..4]
      hour = 5
    busCount = 0
    busHour = hour
    replyMessage = "\n#{toName}行き \n"
    while busCount < SHOW_MAX_BUS or hour+2 > busHour
      nextBus = []
      key = "#{to}_#{allDay[dayIndex]}_time#{busHour}"
      while robot.brain.data[key] is null and busHour <= 24
        busHour++
      if busHour > 24
        replyMessage += "最後のバスです"
        break
      for value, index in robot.brain.data[key]
        parseTime = parseInt(value.match(/\d{2}/))
        #シャトルバスの場合の判定
        if not parseBus = value.match(/\D/)
          parseBus = viaS[0]
        if (busHour > hour and ///#{bus}///.test(parseBus)) or (parseTime > min and ///#{bus}///.test(parseBus))
          nextBus.push(value)
          busCount++
        if busCount < SHOW_MAX_BUS
          break
      replyMessage += "#{busHour}時：#{nextBus.join()}\n"
      busHour++
    msg.reply replyMessage

  #コマンドから全てのバスの時刻表を取得
  robot.respond /data update/i, (msg) ->
    now = new Date
    for value,index in allDay
      console.log "#{value}:#{url[index]}"
      getBusSchedule("minakusa",value,url[index],robot)
      console.log "#{value}:#{urlKusatsu[index]}"
      getBusSchedule("kusatsu",value,urlKusatsu[index],robot)

#曜日の要素取得
getDayOfWeek = (now,robot) ->
  dayIndex = 0
  if PublicHoliday.isPublicHoliday(now) or now.getDay() is 0
    dayIndex = 2
  else if now.getDay() is 6
    dayIndex = 1
  return dayIndex
