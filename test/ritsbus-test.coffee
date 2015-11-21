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

  it 'check time option parse after n minutes', ->
    # デフォルト
    date = new Date
    searchDate = getSearchDate(date, ["P"])
    date = new Date(date.getTime() + 7*60*1000)
    expect(date).to.eql(searchDate)

    # 20分後
    date = new Date
    searchDate = getSearchDate(date, ["20","P"])
    date = new Date(date.getTime() + 20*60*1000)
    expect(date).to.eql(searchDate)

    # 0分後
    date = new Date
    searchDate = getSearchDate(date, ["0","P"])
    date = new Date(date.getTime() + 0*60*1000)
    expect(date).to.eql(searchDate)

  it 'check time option parse hh:mm style', ->
    # hh:mm 形式
    date = new Date
    searchDate = getSearchDate(date, ["10:10", "P"])
    date.setHours(10)
    date.setMinutes(10)
    date.setSeconds(0)
    expect(date).to.eql(searchDate)

    # parseIntで小数点以下は無視
    date = new Date
    searchDate = getSearchDate(date, ["P","15:15.111111111111"])
    date.setHours(15)
    date.setMinutes(15)
    date.setSeconds(0)
    expect(date).to.eql(searchDate)

    # 分が59を超えると59分のバス表示
    date = new Date
    searchDate = getSearchDate(date, ["10:70", "P"])
    date.setHours(10)
    date.setMinutes(59)
    date.setSeconds(0)
    expect(date).to.eql(searchDate)

    # 時が24を超えると24時に設定
    date = new Date
    searchDate = getSearchDate(date, ["26:10", "P"])
    date.setHours(24)
    date.setMinutes(10)
    date.setSeconds(0)
    expect(date).to.eql(searchDate)

    # 頭に-をつけてもその後の数値で判断
    date = new Date
    searchDate = getSearchDate(date, ["P","-18:30"])
    date.setHours(18)
    date.setMinutes(30)
    date.setSeconds(0)
    expect(date).to.eql(searchDate)

    # 正規表現に通らない場合は7分後のデフォルトタイムで返す
    date = new Date
    searchDate = getSearchDate(date, ["P","18:-30"])
    date = new Date(date.getTime() + 7*60*1000)
    expect(date).to.eql(searchDate)

  it 'check parse minakusa ordinary data', ->
    json = 'test/parsedJSON/minakusa_ordinary.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/minakusa_ordinary.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody("minakusa", "ordinary", html.toString()))

  it 'check parse minakusa saturday data', ->
    json = 'test/parsedJSON/minakusa_saturday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/minakusa_saturday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody("minakusa", "saturday", html.toString()))

  it 'check parse minakusa holiday data', ->
    json = 'test/parsedJSON/minakusa_holiday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/minakusa_holiday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody("minakusa", "holiday", html.toString()))

  it 'check parse kusatsu ordinary data', ->
    json = 'test/parsedJSON/kusatsu_ordinary.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/kusatsu_ordinary.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody("kusatsu", "ordinary", html.toString()))

  it 'check parse kusatsu saturday data', ->
    json = 'test/parsedJSON/kusatsu_saturday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/kusatsu_saturday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody("kusatsu", "saturday", html.toString()))

  it 'check parse kusatsu holiday data', ->
    json = 'test/parsedJSON/kusatsu_holiday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/kusatsu_holiday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody("kusatsu", "holiday", html.toString()))

  it 'check parse ritsumei ordinary data', ->
    json = 'test/parsedJSON/ritsumei_ordinary.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/ritsumei_ordinary.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody("ritsumei", "ordinary", html.toString()))

  it 'check parse ritsumei saturday data', ->
    json = 'test/parsedJSON/ritsumei_saturday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/ritsumei_saturday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody("ritsumei", "saturday", html.toString()))

  it 'check parse ritsumei holiday data', ->
    json = 'test/parsedJSON/ritsumei_holiday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/ritsumei_holiday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parseBody("ritsumei", "holiday", html.toString()))
