chai = require 'chai'
sinon = require 'sinon'
rewire = require 'rewire'
fs = require 'fs'
chai.use require 'sinon-chai'

expect = chai.expect

busSchedule = {
  "minakusa_ordinary_time5":
    null
  "minakusa_ordinary_time6":
    null
  "minakusa_ordinary_time7":
    [ 'P03', 'P15', 'P30', 'P45' ]
  "minakusa_ordinary_time8":
    [ 'か10', 'P15', 'P30', 'P45' ]
  "minakusa_ordinary_time9":
    [ 'P00', 'か10', 'P15', 'か25', 'P35', '西45' ]
  "minakusa_ordinary_time10":
    [ 'P00', '笠02', 'か10', 'P15', 'か25', 'P35', '西45' ]
  "minakusa_ordinary_time11":
    [ 'P00', '笠02', 'か10', 'P15', 'か25', 'P35', '西45' ]
  "minakusa_ordinary_time12":
    [ '00', 'P00', '笠02', 'か10', 'P15', '20', 'か25', '30', 'P35', '45', '西45' ]
  "minakusa_ordinary_time13":
    [ 'P00', 'か10', '15', 'P15', '20', 'か25', '35', 'P35', '西45' ]
  "minakusa_ordinary_time14":
    [ 'P00', 'か10', '15', 'P15', 'か25', '30', '33', 'P35', '42', '西45', '48', '58' ]
  "minakusa_ordinary_time15":
    [ 'P00', '笠02', '10', 'か10', 'P15', '20', 'か25', 'P35', '40', '西45', '48', 'か55' ]
  "minakusa_ordinary_time16":
    [ '00', 'P00', '笠02', '04', '09', 'か10', '15', '18', '21', '24', 'か25', 'P30', '35', '44', '西45', '48', '55', 'か55' ]
  "minakusa_ordinary_time17":
    [ '00', 'P00', '笠02', '西03', '04', '09', 'か10', '15', 'P18', '西20', '21', '28', 'P30', '35', 'か40', '43', '西45', '48', '53', 'P53', '58' ]
  "minakusa_ordinary_time18":
    [ '00', 'P00', '笠02', '07', 'P08', 'か10', '14', 'P16', '22', '西25', 'P32', '36', 'か40', '42', '西43', 'P45', '48', '西51', '55' ]
  "minakusa_ordinary_time19":
    [ '00', 'P00', '笠02', 'か05', 'P08', '西10', '18', 'P20', '28', 'P30', '西35', '38', 'か40', 'P45', '48', '西53', '55' ]
  "minakusa_ordinary_time20":
    [ '00', 'P00', 'P08', 'か10', 'P18', '西22', 'P30', '35', '西35', 'か40', 'P48', '西50' ]
  "minakusa_ordinary_time21":
    [ '00', 'P00', '西03', 'か10', 'P15', '25', 'P35', 'か40', 'P45', '西48', '58' ]
  "minakusa_ordinary_time22":
    [ '西00', 'か05', 'P10', 'P15', 'P25', 'か35', 'P45' ]
  "minakusa_ordinary_time23":
    [ 'か00', 'P10' ]
  "minakusa_ordinary_time24":
    null
}

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
    file = 'test/html/minakusa_ordinary.html'
    stat = fs.statSync file
    fd = fs.openSync file, 'r'
    html = fs.readSync fd, stat.size, 0, "utf-8"
    expect(busSchedule).to.eql(parse("minakusa","ordinary",html.toString()))
