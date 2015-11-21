chai = require 'chai'
sinon = require 'sinon'
rewire = require 'rewire'
fs = require 'fs'
chai.use require 'sinon-chai'
expect = chai.expect
ritsBus = rewire('../src/ritsbus')
parseBody = ritsBus.__get__('parseBody')
getSearchDate = ritsBus.__get__('getSearchDate')

describe 'ritsbus', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/ritsbus')(@robot)

  assertTimeOptionAfterMinutes = (expectOption, expectMinutes) ->
    date = new Date
    searchDate = getSearchDate(date, expectOption)
    date = new Date(date.getTime() + expectMinutes*60*1000)
    expect(date).to.eql(searchDate)

  it 'can apply time option (after n minutes)', ->
    # デフォルト
    assertTimeOptionAfterMinutes(["P"], 7)
    # 0分後
    assertTimeOptionAfterMinutes(["0", "P"], 0)
    # 20分後
    assertTimeOptionAfterMinutes(["20", "P"], 20)
    # 2時間後(120分)
    assertTimeOptionAfterMinutes(["120", "P"], 120)

  assertTimeOption24HourClock = (expectOption, hours, minutes, seconds) ->
    date = new Date
    searchDate = getSearchDate(date, expectOption)
    date.setHours(hours)
    date.setMinutes(minutes)
    date.setSeconds(seconds)
    expect(date).to.eql(searchDate)

  it 'can apply time option (hh:mm style)', ->
    # hh:mm 形式
    assertTimeOption24HourClock(["10:10", "P"], 10, 10, 0)
    # parseIntで小数点以下は無視
    assertTimeOption24HourClock(["P", "15:15.111111111111"], 15, 15, 0)
    # 分が59を超えると59分のバス表示
    assertTimeOption24HourClock(["10:70", "P"], 10, 59, 0)
    # 時が24を超えると24時に設定
    assertTimeOption24HourClock(["26:10", "P"], 24, 10, 0)
    # 頭に-をつけてもその後の数値で判断
    assertTimeOption24HourClock(["P", "-18:30"], 18, 30, 0)

  it 'cannot aplly time option', ->
    # parseできないパターン
    assertTimeOptionAfterMinutes(["2*60*60*1000", "P"], 7)
    # 3時間後（2時間を超えるのでデフォルトタイム）
    assertTimeOptionAfterMinutes(["180", "P"], 7)
    # 24時間後（2時間を超えるのでデフォルトタイム）
    assertTimeOptionAfterMinutes(["1440", "P"], 7)
    # 正規表現に通らない場合は7分後のデフォルトタイムで返す
    assertTimeOptionAfterMinutes(["P", "18:-30"], 7)

  assertParseHTML = (destination, category) ->
    json = "test/parsedJSON/#{destination}_#{category}.json"
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = "test/html/#{destination}_#{category}.html"
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody(destination, category, html.toString()))

  assertParseHTMLDestination = (destination) ->
    assertParseHTML(destination, "ordinary")
    assertParseHTML(destination, "saturday")
    assertParseHTML(destination, "holiday")

  it 'check parse minakusa', ->
    assertParseHTMLDestination("minakusa")

  it 'check parse kusatsu', ->
    assertParseHTMLDestination("kusatsu")

  it 'check parse ritsumei', ->
    assertParseHTMLDestination("ritsumei")
