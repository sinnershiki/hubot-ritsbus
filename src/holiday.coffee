class PublicHoliday
  #祝日ならtrueを返す
  isHoliday: (date) ->
    if checkNewYearsDay(date)
      return true
    else if checkComingOfAgeDay(date)
      return true
    else if checkNationalFoundationDay(date)
      return true
    else if checkVernalEquinoxHoliday(date)
      return true
    else if checkShowDay(date)
      return true
    else if checkGoldenWeek(date)
      return true
    else if checkMountainDay(date)
      return true
    else if checkMarineDay(date)
      return true
    else if checkRespectForTheAgedDay(date)
      return true
    else if checkSportsDay(date)
      return true
    else if checkCultureDay(date)
      return true
    else if checkLaborThanksgivingDay(date)
      return true
    else if checkTheEmperorsBirthday(date)
      return true
    return false

  #元日
  checkNewYearsDay = (date) ->
    month = 1
    day = 1
    return isRegularHoliday(date, month, day)

  #成人の日
  checkComingOfAgeDay = (date) ->
    month = 1
    day = 1 #月曜日
    week = 2 #2週目
    return isIrregularHoliday(year, month, week, day)

  #建国記念日
  checkNationalFoundationDay = (date) ->
    month = 2
    day = 11
    return isRegularHoliday(date, month, day)

  #春分の日
  checkVernalEquinoxHoliday = (date) ->
    month = 3
    day = 20
    #春分の日独特の日程判定（2025年までしか動作は保証されません）
    switch year%4
      when 2,3
        day = 21
    return isRegularHoliday(date, month, day)

  #昭和の日
  checkShowaDay = (date) ->
    month = 4
    day = 29
    return isRegularHoliday(date, month, day)

  #GoldenWeek記憶処理（特殊
  #憲法記念日，みどりの日，こどもの日
  checkGoldenWeek = (date) ->
    month = 5
    day = 3
    for i in [0..2]
      holiday = new Date(date.getFullYear(), month-1, day)
      if holiday.getDay() is 0
        day++
        holiday.setDate(day)
      if isRegularHoliday(date, month-1, day)
        return true
      day++
    return false

  #山の日（2016年から
  checkMountainDay = (date) ->
    year = parseInt(date.getFullYear())
    if year > 2015
      month = 8
      day = 11
      return isRegularHoliday(date, month, day)
    return false

  #海の日
  checkMarineDay = (date) ->
    month = 7
    week = 3 #3週目
    day = 1 #休みの曜日
    return isIrregularHoliday(year, month, week, day)

  #敬老の日
  checkRespectForTheAgedDay = (date) ->
    month = 9
    week = 3 #3週目
    day = 1 #休みの曜日
    return isIrregularHoliday(year, month, week, day)

  #秋分の日
  checkAutumnEquinoxHoliday = (date) ->
    month = 9
    day = 22
    #秋分の日独特の日程判定（2041年までしか動作は保証されません）
    switch date.getFullYear() % 4
      when 1,2,3
        day = 23
    return isRegularHoliday(date, month, day)

  #体育の日
  checkSportsDay = (date) ->
    month = 10
    week = 2 #二周目
    day = 1 #休みの曜日
    return isIrregularHoliday(year, month, week, day)

  #文化の日
  checkCultureDay = (date) ->
    month = 11
    day = 3
    return isRegularHoliday(date, month, day)

  #勤労感謝の日
  checkLaborThanksgivingDay = (date) ->
    month = 11
    day = 23
    return isRegularHoliday(date, month, day)

  #天皇誕生日
  checktheEmperorsBirthday = (date) ->
    month = 12
    day = 23
    return isRegularHoliday(date, month, day)

  #日付が決まった祝日の振替休日処理
  holidayToMakeUpDay = (holiday) ->
    if holiday.getDay() is 0
      day++
      holiday.setDate(day)
    return holiday

  #dateとholidayが同一日の場合trueを返す
  isRegularHoliday = (date, holidayMonth, holidayDay) ->
    holiday = new Date(date.getFullYear(), holidayMonth-1, holidayDay)
    holiday = holidayToMakeUpDay(holiday)
    if date.getTime() == holiday.getTime()
      return true
    return false

  #週と曜日が決まっている祝日の記憶（振替回避処理込）
  isIrregularHoliday = (date, holidayMonth, holidayWeek, holidayDay) ->
    day = 1 + (holidayWeek - 1 ) * 7
    holiday = new Date(date.getFullYear, holidayMonth-1, day)
    for value in [day..day+6]
      holiday.setDate(value)
      if (holiday.getDay() is holidayDay) and (date.getTime() == holiday.getTime())
      return true
    return false
