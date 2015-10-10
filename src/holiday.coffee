# Description:
#   バスbotで使う祝日判定
#
# Commands:
#   hubot update holiday - 祝日の情報更新
#

cron = require('cron').CronJob
module.exports = (robot) ->
    #毎年1/1の1時に祝日データの更新
    new cron('0 1 1 1 *', () ->
        updatePublickHoliday(new Date)
    ).start()

    #コマンドから祝日のデータ更新
    robot.respond /holiday update/i, (msg) ->
        updatePublicHoliday(new Date)

#祝日更新関数
updatePublicHoliday = (now) ->
    year = now.getFullYear()
    key = "publicHoliday_#{year}"
    robot.brain.data[key] = []
    brainPublicHoliday(year,robot)

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
