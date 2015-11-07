chai = require 'chai'
sinon = require 'sinon'
rewire = require 'rewire'
fs = require 'fs'
chai.use require 'sinon-chai'
expect = chai.expect
ritsBus = rewire('../src/ritsbus')
parse = ritsBus.__get__('parseBody')

describe 'ritsbus', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/ritsbus')(@robot)

  it 'registers a respond listener', ->
    expect(@robot.respond).to.have.been.calledWith(/update/i)

  it 'check parse minakusa ordinary data', ->
    json = 'test/parsedJSON/minakusa_ordinary.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/minakusa_ordinary.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parse("minakusa", "ordinary", html.toString()))

  it 'check parse minakusa saturday data', ->
    json = 'test/parsedJSON/minakusa_saturday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/minakusa_saturday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parse("minakusa", "saturday", html.toString()))

  it 'check parse minakusa holiday data', ->
    json = 'test/parsedJSON/minakusa_holiday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/minakusa_holiday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parse("minakusa", "holiday", html.toString()))

  it 'check parse kusatsu ordinary data', ->
    json = 'test/parsedJSON/kusatsu_ordinary.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/kusatsu_ordinary.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parse("kusatsu", "ordinary", html.toString()))

  it 'check parse kusatsu saturday data', ->
    json = 'test/parsedJSON/kusatsu_saturday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/kusatsu_saturday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parse("kusatsu", "saturday", html.toString()))

  it 'check parse kusatsu holiday data', ->
    json = 'test/parsedJSON/kusatsu_holiday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/kusatsu_holiday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parse("kusatsu", "holiday", html.toString()))

  it 'check parse ritsumei ordinary data', ->
    json = 'test/parsedJSON/ritsumei_ordinary.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/ritsumei_ordinary.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parse("ritsumei", "ordinary", html.toString()))

  it 'check parse ritsumei saturday data', ->
    json = 'test/parsedJSON/ritsumei_saturday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/ritsumei_saturday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parse("ritsumei", "saturday", html.toString()))

  it 'check parse ritsumei holiday data', ->
    json = 'test/parsedJSON/ritsumei_holiday.json'
    busSchedule = JSON.parse(fs.readFileSync(json, "utf-8"))
    file = 'test/html/ritsumei_holiday.html'
    html = fs.readFileSync file, "utf-8"
    expect(busSchedule).to.eql(parse("ritsumei", "holiday", html.toString()))
