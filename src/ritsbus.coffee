# Description:
#   近江鉄道バスfrom立命館to南草津(or草津)の時刻表通知
#
# Commands:
#   hubot bus <n分後> <シャトル|P|かがやき|笠山|パナ西|草津> - 経由地
#

Buffer = require('buffer').Buffer
cron = require('cron').CronJob
request = require('request')
cheerio = require('cheerio')
iconv = require('iconv')

viaS = ["直","shuttle","シャトル","直行","S"]
viaP = ["P","パナ東"]
viaC = ["か","かがやき"]
viaK = ["笠","笠山"]
viaN = ["西","パナ西"]
allDay = ["ordinary","saturday","holiday"]
allDayName = ["平日","土曜日","日曜・祝日"]
url = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2","http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=2&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2","http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1050&KaiKbn=NOW&pole=2"]
urlKusatsu = ["http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=1&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1","http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=2&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1","http://time.khobho.co.jp/ohmi_bus/tim_dsp.asp?projCd=3&eigCd=7&teicd=1050&KaiKbn=NOW&pole=1"]

module.exports = (robot) ->
    #毎年1/1の1時に祝日データの更新
    new cron('0 1 1 1 *', () ->
        now = new Date
        year = now.getFullYear()
        key = "publicHoliday_#{year}"
        robot.brain.data[key] = []
        brainPublicHoliday(year,robot)
    ).start()

    #毎日午前3時にその曜日の時刻表を取得し，データを更新する(エラー処理などはそのうち追加
    new cron('0 3 * * *', () ->
        now = new Date
        console.log "午前3時:#{now}"
        #dayIndex = getDayOfWeek(now,robot)
        #getBusSchedule(allDay[dayIndex],url[dayIndex],robot)
    ).start()

    #robot.respond /public holiday/i, (msg) ->
    #    d = new Date
    #    key = "publicHoliday_#{d.getFullYear()}"
    #    console.log robot.brain.data[key]

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
            nextTime = 10
            kind = option[0]
        #一つ目の引数が数字である場合，2つ目の引数から行き先を判定
        else
            kind = option[1]
        #バスの行き先判定
        toName = "南草津"
        if kind in viaS #(kind is via[0]) or (kind is viaName[0])
            bus = "直"
        else if kind in viaP #(kind is via[1]) or (kind is viaName[1])
            bus = "P"
        else if kind in viaC #(kind is via[2]) or (kind is viaName[2])
            bus = "か"
        else if kind in viaK #(kind is via[3]) or (kind is viaName[3])
            bus = "笠"
        else if kind in viaN #(kind is via[4]) or (kind is viaName[4])
            bus = "西"
        else if /^草津*/.test(kind)
            to  = "kusatsu"
            toName = "草津"
        #今の時間帯にnextTime（デフォルトでは10）分後から3時間以内にあるバスを
        #5件まで次のバスとして表示する
        afterDate = new Date(now.getTime() + nextTime*60*1000)
        hour = afterDate.getHours()
        min = afterDate.getMinutes()
        if hour in [0..4]
            hour = 5
        count = 0
        busHour = hour
        #str = "@#{msg.message.user.name} \n"
        str = "\n"
        str += "#{toName}行き \n"
        flag = 0

        loop
            nextBus = []
            console.log key = "#{to}_#{allDay[dayIndex]}_time#{busHour}"
            while robot.brain.data[key] is null
                busHour++
                if busHour > 24
                    flag = 1
                    break

            if flag is 1
               console.log "last bus"
               str += "最後のバスです"
               break
            for value, index in robot.brain.data[key]
                tmpTime = parseInt(value.match(/\d{2}/))
                #シャトルバスの場合の判定
                if not tmpBus = value.match(/\D/)
                    tmpBus = viaS[0]
                if busHour > hour and ///#{bus}///.test(tmpBus)
                    nextBus.push(value)
                    count++
                else if tmpTime > min and ///#{bus}///.test(tmpBus)
                    nextBus.push(value)
                    count++
                if count is 5
                    break
            str += busHour
            str += "時："
            str += nextBus.join()
            if count is 5 or hour+2 < busHour
                break
            busHour++
            str += "\n"
        msg.reply str

    #コマンドから全てのバスの時刻表を取得
    robot.respond /get data/i, (msg) ->
        console.log "get data now"
        now = new Date
        brainPublicHoliday(now.getFullYear(),robot)
        for value,index in allDay
            console.log "#{value}:#{url[index]}"
            getBusSchedule("minakusa",value,url[index],robot)
            console.log "#{value}:#{urlKusatsu[index]}"
            getBusSchedule("kusatsu",value,urlKusatsu[index],robot)

#曜日の要素取得
getDayOfWeek = (now,robot) ->
    dayIndex = 0
    if isPublicHoliday(now,robot) or now.getDay() is 0
        dayIndex = 2
    else if now.getDay() is 6
        dayIndex = 1
    return dayIndex

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

#祝日判定
isPublicHoliday = (d,robot) ->
    key = "publicHoliday_#{d.getFullYear()}"
    if not robot.brain.data[key]
        brainPublicHoliday(d.getFullYear(),robot)
    for x in robot.brain.data[key]
        x = x.split(/-/)
        month = parseInt(x[1])
        date =  parseInt(x[2])
        if (month-1) is d.getMonth() and date is d.getDate()
            return true
    return false

#祝日を記憶させる
brainPublicHoliday = (year,robot) ->
    key = "publicHoliday_#{year}"
    robot.brain.data[key] = []
    brainNewYearsDay(year,robot)
    #msg.send "元日"
    brainComingOfAgeDay(year,robot)
    #msg.send "成人の日"
    brainNationalFoundationDay(year,robot)
    #msg.send "建国記念日"
    brainVernalEquinoxHoliday(year,robot)
    #msg.send "春分の日"
    brainShowaDay(year,robot)
    #msg.send "昭和の日"
    brainGoldenWeek(year,robot)
    #msg.send "ゴールデンウィーク"
    brainMarineDay(year,robot)
    #msg.send "海の日"
    brainMountainDay(year,robot)
    #msg.send "山の日(2016年から)"
    brainRespectForTheAgedDay(year,robot)
    #msg.send "敬老の日"
    brainAutumnEquinoxHoliday(year,robot)
    #msg.send "秋分の日"
    brainSportsDay(year,robot)
    #msg.send "体育の日"
    brainCultureDay(year,robot)
    #msg.send "文化の日"
    brainLaborThanksgivingDay(year,robot)
    #msg.send "勤労感謝の日"
    braintheEmperorsBirthday(year,robot)
    #msg.send "天皇誕生日"

#元日を記憶させる
brainNewYearsDay = (year,robot) ->
    month = 1
    date = 1
    brainRegularDay(year,month,date,robot)

#成人の日を記憶させる
brainComingOfAgeDay = (year,robot) ->
    month = 1
    day = 1 #休みの曜日
    week = 2 #2週目
    brainNotConstantDay(year,month,week,day,robot)

#建国記念日
brainNationalFoundationDay = (year,robot) ->
    month = 2
    date = 11
    brainRegularDay(year,month,date,robot)

#春分の日
brainVernalEquinoxHoliday = (year,robot) ->
    month = 3
    date = 20
    #春分の日独特の日程判定（2025年までしか動作は保証されません）
    switch year%4
        when 0,1
            date = 20
        when 2,3
            date = 21
    brainRegularDay(year,month,date,robot)

#昭和の日
brainShowaDay = (year,robot) ->
    month = 4
    date = 29
    brainRegularDay(year,month,date,robot)

#GoldenWeek記憶処理（特殊
#憲法記念日，みどりの日，こどもの日
brainGoldenWeek = (year,robot) ->
    month = 5
    date = 3
    loopend = date+3
    while date < loopend
        d = new Date(year,month-1,date)
        if d.getDay() is 0
            date++
            loopend++
            d = new Date(year,month-1,date)
        brainRegularDay(year,month,date,robot)
        date++

#山の日（2016年から
brainMountainDay = (year,robot) ->
    year = parseInt(year)
    if year > 2015
        month = 8
        date = 11
        brainRegularDay(year,month,date,robot)

#海の日
brainMarineDay = (year,robot) ->
    month = 7
    week = 3 #3週目
    day = 1 #休みの曜日
    brainNotConstantDay(year,month,week,day,robot)

#敬老の日
brainRespectForTheAgedDay = (year,robot) ->
    month = 9
    week = 3 #3週目
    day = 1 #休みの曜日
    brainNotConstantDay(year,month,week,day,robot)

#秋分の日
brainAutumnEquinoxHoliday = (year,robot) ->
    month = 9
    date = 22
    #秋分の日独特の日程判定（2041年までしか動作は保証されません）
    switch year%4
        when 0
            date = 22
        when 1,2,3
            date = 23
    brainRegularDay(year,month,date,robot)

#体育の日
brainSportsDay = (year,robot) ->
    month = 10
    week = 2 #二周目
    day = 1 #休みの曜日
    brainNotConstantDay(year,month,week,day,robot)

#文化の日
brainCultureDay = (year,robot) ->
    month = 11
    date = 3
    brainRegularDay(year,month,date,robot)

#勤労感謝の日
brainLaborThanksgivingDay = (year,robot) ->
    month = 11
    date = 23
    brainRegularDay(year,month,date,robot)

#天皇誕生日
braintheEmperorsBirthday = (year,robot) ->
    month = 12
    date = 23
    brainRegularDay(year,month,date,robot)

#日付が決まった祝日の記憶（振替回避処理込）
brainRegularDay = (year,month,date,robot) ->
    d = new Date(year,month-1,date)
    key = "publicHoliday_#{year}"
    tmp = robot.brain.data[key]
    if not tmp
        tmp = []
    if d.getDay() is 0
        date++
        d.setDate(date)
    if d not in tmp
        tmp.push("#{year}-#{month}-#{d.getDate()}")
        robot.brain.data[key] = tmp
        robot.brain.save()

#週と曜日が決まっている祝日の記憶（振替回避処理込）
brainNotConstantDay = (year,month,week,day,robot) ->
    date = [1..7]
    for x,i in date
        date[i] = x+(week-1)*7
    key = "publicHoliday_#{year}"
    tmp = robot.brain.data[key]
    d = new Date(year,month-1,date[0])
    for x in date
        d.setDate(x)
        if d.getDay() is day
            break
    if d not in tmp
        tmp.push("#{year}-#{month}-#{d.getDate()}")
        robot.brain.data[key] = tmp
        robot.brain.save()

