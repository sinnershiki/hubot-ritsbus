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
    expect(busSchedule).to.eql(parse("minakusa","ordinary",html.toString()))
