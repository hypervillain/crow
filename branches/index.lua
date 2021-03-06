OR = "or"
AND = "and"
MOST = "most"
CONJUNCTION = OR -- see README
PULSE_TRIG = 0.16 -- change this
PULSE_VOLTS = 8 -- change this

SIGNATURE = 8

events = {
  steps = 0,
  inputRepeats = { 0, 0 }, -- unused
  outputRepeats = { 0, 0, 0, 0 },
  prevInputValue = { true, true },
  prevOutputValue = { true, true, true, true }
} -- this could be heavily optimized,
-- but let's see if it works first!

function map(func, array)
  local arr = {}
  for i,v in ipairs(array) do
    arr[i] = func(v)
  end
  return arr
end

-- -- -- -- -- -- -- -- -- -
-- Questions / conditions --
-- -- -- -- -- -- -- -- -- -
-- TODO
  -- ifRand()
  -- and ifRand1()
  -- sum of positive logical outputs

function events:get(elem, index, maybeF)
  if (maybeF) then
    return maybeF(events[elem][index])
  end
  return events[elem][index]
end

function ifPrevOutput(o)
  return function() return events:get("prevOutputValue", o) end
end
function ifNotPrevOutput(o)
  return function() return not events:get("prevOutputValue", o) end
end

function ifPrevInput(i)
  return function() return events:get("prevInputValue", i) end
end

function ifNotPrevInput(i)
  return function() return not events:get("prevInputValue", i) end
end

function ifMaxRepeat(o, max)
  return function() return events:get("outputRepeats", o, function(e) return e < max end) end
end

function ifInput(i)
  function _ifInput(_i)
    return i == _i
  end
  return _ifInput
end
function ifNotInput(i) return function(...)
  local args = { ... }
    return not ifInput(i)(args)
  end
end

function ifOutput(oIndex)
  function _ifOutput(bools)
    return bools[oIndex] == true
  end
  return _ifOutput
end

function ifNotOutput(oIndex)
  return function(...) 
    local args = { ... }
    return not ifOutput(oIndex)(args)
  end
end

function ifStep(...)
  local args = { ... }
  return function()
    local bool = false
    print(table.unpack(args))
    for a, v in ipairs(args) do
      print(a)
      print('--')
      -- assumes steps count has just been incremented
      if (v == events.steps) then
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
    return not ifStep(table.unpack(args))()
  end
end
-- -- -- -- -- -- -- -- -- -
-- End of questions -- -- --
-- -- -- -- -- -- -- - -- --

-- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Evaluate a table of booleans -- -- --
-- based on user selected conjunction --
-- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Todo
  -- by output conjunction
  -- define prop-types-like conditions: method().required
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

-- -- -- -- -- -- -- -- -- -- -- --
-- For each logical output, scan --
-- and run its set of conditions --
-- -- -- -- -- -- -- -- -- -- -- --
function evaluateLogicalOutputs(conjunction, i)
  local outputBools = {}
  for o = 1, 4 do
    outputBools[o] = eval(
      conjunction,
      i,
      table.unpack(
        map(
          function (f)
            return f(i, o, outputBools)
          end,
          logicalOutputs[o]
        )
      )
    )
  end
  return outputBools
end

-- -- -- -- -- -- -- -- -- -- -- -- --
-- After change, update events table -
-- -- -- -- -- -- -- -- -- -- -- -- --
function updateEvents(i, bools)
  events.prevInputValue[i] = true
  events.prevInputValue[3 - i] = false
  for o = 1, 4 do
    if (bools[o] == true) then
      events.outputRepeats[o] = events.outputRepeats[o] + 1
    else events.outputRepeats[o] = 0
    end
    events.prevOutputValue[o] = bools[o]
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- --
-- Move the sequence forward until signature --
-- Then, reset --
-- -- -- -- -- -- -- -- -- -- -- -- --
function handleStep()
  if (events.steps == SIGNATURE) then
    events.steps = 1
    events.outputRepeats = map(function() return 0 end, events.outputRepeats)
    return
  end
  events.steps = events.steps + 1
end

-- -- -- --   -- change -  --
-- change -       -- change -
-- -- -- --    -- change - --
-- -- change -- -- -- -- -- -
function attachInputChange(i)
  function change(_)
    handleStep() -- sequence rotation
    local bools = evaluateLogicalOutputs(CONJUNCTION, i)
    for o = 1, 4 do
      if (bools[o] == true) then
       output[o]()
      end
      events.prevOutputValue[o] = bool
    end
    updateEvents(i, bools)

  end
  return change
end

function init()
  for i = 1, 2 do
    input[i].mode('change', 1.0, 0.1, 'rising')
    input[i].change = attachInputChange(i)
  end
  for i = 1, 4 do
    output[i].action = pulse(PULSE_TRIG, PULSE_VOLTS, 1)
  end
end

-- logicalOutputs = {
--   { ifInput(1) },
--   {  ifNotInput(1), ifNotOutput(4) },
--   {  ifMaxRepeat(1, 3) },
--   { ifMaxRepeat(4, 3) }
-- } -- change this :)

logicalOutputs = {
  { ifStep(1, 4) },
  { ifNotOutput(1) },
  { ifStep(1, 4), ifInput(2) },
  {
    -- add your logic here 🏄‍♂️
  },
  {}
}
