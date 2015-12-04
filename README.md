[![Build Status](https://travis-ci.org/sinnershiki/hubot-ritsbus.svg?branch=master)](https://travis-ci.org/sinnershiki/hubot-ritsbus)


# hubot-ritsbus

search ohmibus

See [`src/ritsbus.coffee`](src/ritsbus.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-ritsbus --save`

Then add **hubot-ritsbus** to your `external-scripts.json`:

```json
[
  "hubot-ritsbus"
]
```

## Sample Interaction

This example assumes a 12:00.

```
user1>> hubot bus
hubot>> 南草津駅行き(12:07以降のバス)
12時：か10,P15,20,か25,30,P35,45

user1>> hubot bus 30
hubot>> 南草津駅行き(12:30以降のバス)
12時：P35,45,西45
13時：P00,か10,15,P15

user1>> hubot bus 22:00
hubot>> 南草津駅行き(22:00以降のバス)
22時：か05,P10,P15,P25,か35,P45
23時：か00

user1>> hubot bus S
hubot>> 南草津駅行き(12:07以降のバス)
12時：20,30,45
13時：15,20,35
14時：15

user1>> hubot bus P
hubot>> 南草津駅行き(12:07以降のバス)
12時：P15,P35
13時：P00,P15,P35
14時：P00,P15

user1>> hubot bus か
hubot>> 南草津駅行き(12:07以降のバス)
12時：か10,か25
13時：か10,か25
14時：か10,か25

user1>> hubot bus 18:00 S
hubot>> 南草津駅行き(18:00以降のバス)
18時：07,14,22,36,42,48,55

user1>> hubot bus S 18:00
hubot>> 南草津駅行き(18:00以降のバス)
18時：07,14,22,36,42,48,55

user1>> hubot kbus
hubot>> 草津駅行き(12:07以降のバス)
12時：P30
13時：P00,P30
14時：P00,P30

user1>> hubot rbus
hubot>> 立命館大学行き(12:07以降のバス)
12時：15,21,西22,30,笠30,36,P37
```
