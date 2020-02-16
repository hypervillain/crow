/*

For each ping, get current time and store it in an array of pingTimes.
Then, re-calculate avrgTimeBetweenPings, a value that approximates time (in milliseconds) between pings.
--> Math.ceil(60000 / avrgTimeBetweenPings) would give you the current approximate BPM

For each trig, set pin to HIGH for a bit less than (current time + avrgTimeBetweenPings).
It opens a window where bursts can be played. In a real life situation, the chances that a window opens depend on CV value.


TODO: progressively flush pingTimes, to allow dynamic changes in ping (and window)


Ternary dividers

[0, 0, 0, 1, 0]
[0, 0, 0, 1, 1]
[1, 0, 1, 0, 1]
[1, 1, 1, 0, 1]
[0, 1, 1, 1]

*/

// used to reproduce IRL ping
const externalBPM = 124
const externalPingDelay = 60000 / externalBPM

let LOW = false
let HIGH = true
let WINDOW = LOW


const pingTimes = []
const schedule = []

let lastTrigEvent
let avrgTimeBetweenPings

function getMillis(hrtime) {
  const nanoseconds = (hrtime[0] * 1e9) + hrtime[1];
  return milliseconds = nanoseconds / 1e6;
}

function calculateBPM() {
  if (pingTimes.length > 1) {
    const toAvg = []
    pingTimes.reduce((a, b) => {
      toAvg.push(a - b)
      return b
    })
    
    avrgTimeBetweenPings = toAvg.reduce((a, b) => (a + b)) / toAvg.length
    // avrgBPM = Math.ceil(60000 / avrg)
  }
}

function calculatePing() {
  const time = process.hrtime()
  pingTimes.unshift(getMillis(time))
  if (pingTimes.length > 4) {
    pingTimes.pop()
  }
  calculateBPM()
}


const binaryDividers = [
  [1, 1],
  [0, 1],
  [1, 1, 1, 1],
  [0, 0, 1, 1],
  [1, 0, 1, 1]
]

function scheduleGateEvents() {
  if (schedule.length) {
    // I _think_ it means we should not schedule things yet
    return
  }
  const divider = binaryDividers[Math.floor(Math.random() * binaryDividers.length)]
  
  /*
    lastTrigEvent = 1s, avrgTimeBetweenPings = 1s
    schedule: 2s - 1s / (step in divider)

  */
  
  // delimits burst range
  const nextTimeStep = lastTrigEvent + avrgTimeBetweenPings

  divider.forEach((step, i) => {
    if (step) {
      const slice = (nextTimeStep - lastTrigEvent) / divider.length
      schedule.push({
        millis: lastTrigEvent + (slice * i),
        divider,
        step: i,
      })
    }
  })
}

function onTrig() {
  console.log('---')
  console.log('TRIG')
  lastTrigEvent = getMillis(process.hrtime())
  if (avrgTimeBetweenPings) { // just checking
    const nextTimeStep = lastTrigEvent + avrgTimeBetweenPings
    const windowRange = (nextTimeStep) / 100 * 90

    // coin flip, chance should come from CV value
    if (Math.random() > 0.49) {
      WINDOW = HIGH
      scheduleGateEvents()
      setTimeout(() => WINDOW = LOW, windowRange)
    } else {
      WINDOW = LOW
    }
  }
}


function loop() {
  const millis = getMillis(process.hrtime())
  schedule.forEach((event, i) => {
    if (millis >= event.millis) {
      console.log('PLAY', event.divider)
      schedule.splice(i, 1)
    }
  })
}

// Simulates external ping
setInterval(calculatePing, externalPingDelay);

// Simulates external trig
setInterval(onTrig, externalPingDelay);

// Simulates loop
setInterval(loop, externalPingDelay / 1024)



/** Trig len 
 * 
 * 
{ '1': 32,
  '2': 16,
  '3': 10.666666666666666,
  '4': 8,
  '5': 6.4,
  '6': 5.333333333333333,
  '7': 4.571428571428571 
}
*/

const baseTrigLen = 16

// const trigLens = Array(9).fill(1, 0)
// .reduceRight((acc, _, i) => {
//   return i ? { ...acc, [i]: baseTrigLen / i } : acc
// }, {})

// console.log('trigLens', trigLens)