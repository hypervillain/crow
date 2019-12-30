OR = "or"
AND = "and"
MOST = "most"
CONJUNCTION = OR -- see README
PULSE_TRIG = 0.16 -- change this
PULSE_VOLTS = 5 -- change this

SIGNATURE = 8

events = {
  steps = 0,
  outputValue = { 0, 0, 0, 0 },
  prevInputValue = { false, false },
  prevOutputValue = { false, false, false, false }
} -- this could be heavily optimized,
-- but let's see if it works first!

-- helper
function map(func, array)
  local arr = {}
  for i,v in ipairs(array) do
    arr[i] = func(v)
  end
  return arr
end

-- -- -- -- -- -- -- -- -- -- -
-- Beginning of test methods --
-- -- -- -- -- -- -- -- -- -- -
function ifInput(i)
  function _ifInput(_i)
    return i == _i
  end
  return _ifInput
end
function ifNotInput(i) return function(args) return not ifInput(i)(args) end end

function ifPrevInput(i)
  function _ifPrevInput()
    return events.prevInputs[i] == true
  end
  return _ifPrevInput
end
function ifNotPrevInput(i) return function(args) return not ifPrevInput(i)(args) end end

function ifOutput(oIndex)
  function _ifOutput(_, _, outputBools)
    return outputBools[oIndex] == true
  end
  return _ifOutput
end
function ifNotOutput(oIndex) return function(args) return not ifOutput(oIndex)(args) end end

function ifStep(...)
  local args = { ... }
  return function()
    local bool = false
    for _, v in ipairs(args) do
      -- assumes steps count has just been incremented
      if ((v % SIGNATURE) == events.steps) then
        bool = true
        break
      end
    end
    return bool
  end
end
function ifNotStep(...)
  local args = { ... }
  return function()
    return not ifStep(table.unpack(args))
  end
end

-- TODO
  -- ifInRange(oIndex, max)
  -- ifInSeqRange(oIndex, max)
  -- maybe ifRand()
  -- and ifRand1()

-- -- -- -- -- -- -- -- -
-- End of test methods --
-- -- -- -- -- -- -- -- -

-- evaluates a table of booleans based on selected conjunction
function eval(conjunction, ...)
  local count = 0
  local args = { ... }
  for _, v in ipairs(args) do
    if conjunction == MOST and v == true then
      count = count + 1
      break
    elseif conjunction == OR and v == true then
      count = 1
      break
    elseif conjunction == AND and v == false then
      break
    end
  end
  return conjunction == MOST and count >= #args / 2 or count > 0
end

-- For each logical output, scan and run its test conditions
function evaluateLogicalOutputs(conjunction, i)
  local outputBools = {}
  for o = 1, 4 do
    outputBools[o] = eval(
      conjunction,
      i,
      table.unpack(
        map(
          function (f) return f(i, o, outputBools) end,
          logicalOutputs[o]
        )
      )
    )
  end
  return outputBools
end

-- on input change, sets current step in sequence
-- resets step and outputs count if sequence just rotated
function handleStep()
  if (events.steps == SIGNATURE) then
    events.steps = 1
    events.outputValue = map(function() return 0 end, events.outputValue)
    return
  end
  events.steps = events.steps + 1
end

-- returns a change method scoped by input index
function attachInputChange(i)
  function change(_)
    handleStep()
    local bools = evaluateLogicalOutputs(CONJUNCTION, i)
    for o = 1, 4 do
      if (bools[o] == true) then
        outputs[o].action(o) -- mock purposes, delete this
        events.outputValue[i] = events.outputValue[i] + 1
      end
    end
    events.prevInputValue[i] = true
    local rev
    if i == 2 then rev = 1 else i = 2 end -- ...
    events.prevInputValue[rev] = false
  end
  return change
end

-- mocks -- delete all of this
function pulse() return function(o) print(o) end end
inputs = { {}, {}}
outputs = { {}, {}, {}, {}}
-- end of mocks

function init()
  for i = 1, 2 do
    inputs[i].change = attachInputChange(i)
  end
  for i = 1, 4 do
    outputs[i].action = pulse(PULSE_TRIG, PULSE_VOLTS, 1)
  end
end

logicalOutputs = {
  { ifInput(1) },
  { ifInput(2) },
  { ifNotInput(1) },
  { ifNotInput(2) }
} -- change this :)

init() -- delete this
