OR = "or"
AND = "and"
OPERATOR = OR -- change this for unexpected results
PULSE_TRIG = 0.16 -- default trigger time
PULSE_VOLTS = 5 -- default voltage value

SIGNATURE = 8 -- number of steps before event.steps reset
events = {
  steps = 0,
  pastInputs = { 0, 0, 0, 0 },
  lastInputValue = { false, false, false, false }
}

function map(func, array)
  local arr = {}
  for i,v in ipairs(array) do
    arr[i] = func(v)
  end
  return arr
end

function ifInput(i)
  function _ifInput(index)
    return i == index
  end
  return _ifInput
end
function ifNotInput(i) return function(i) return not ifInput(i) end end

function ifOutput(oIndex)
  function _ifOutput(_, _, oBools)
    return oBools[oIndex] == true
  end
  return _ifOutput
end
function ifNotOutput(oIndex) return function(oIndex) return not ifOutput(oIndex) end end

-- en réalité, ifPastInput sert à donner une range max d'events dans la mesure
-- à coder: une fonction qui compte le nombre d'affilée
-- ifPastInput devrait lui utiliser events.lastInputValue
function ifPastInput(i)
  function _ifPastInput()
    return events.pastInputs[i] > 0
  end
  return _ifPastInput
end
function ifNotPastInput(i) return function(i) return not ifPastInput(i)() end end

function ifOutput(oIndex)
  function _ifOutput(_, _, oBools)
    return oBools[oIndex] == true
  end
  return _ifOutput
end
function ifNotOutput(oIndex) return function(oIndex) return not ifOutput(oIndex) end end

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

logicalOuts = {
  { ifInput(1), ifStep(1, 5), ifNotPastInput(1) },
  { ifInput(2) },
  { ifPastInput(1) },
  { ifNotPastInput(1) }
}

-- evaluates a table of booleans
function eval(operator, ...)
  local bool = false
  for _, v in ipairs({ ... }) do
    if operator == OR and v == true then
      bool = true
      break
    end
    if operator == AND and v == false then
      bool = false
      break
    end
  end
  return bool
end

function evaluateLogicalOutputs(operator, i)
  oBools = {}
  for o = 1, 4 do
    oBools[o] = eval(
      operator,
      i,
      table.unpack(
        map(
          function (f) return f(i, o, oBools) end,
          logicalOuts[o]
        )
      )
    )
  end
  return oBools
end

function attachInputChange(i)
  function onChange(v)
    local bools = evaluateLogicalOutputs(OPERATOR, i)
    for o = 1, 4 do
      if (bools[o] == true) then
        outputs[o].action(o) -- mock purposes
      end
    end
  end
  return onChange
end

-- mocks -- this should be deleted
function pulse() return function(o) print("Play output "..o) end end
inputs = { {}, {}}
outputs = { {}, {}, {}, {}}
-- end of mocks

function init()
  for i = 1, 2 do
    inputs[i].change = attachInputChange(i)
  end
  for i = 1, 4 do
    outputs[i].action = pulse(PULSE_TRIG, PULSE_VOLTS, true)
  end
end

init()

print(inputs[1].change())
print(inputs[2].change())
print(inputs[1].change())
print(inputs[2].change())

-- print(inputs[2].change("val2"))

-- print(inputs[1].notMe)
-- print(inputs[2].notMe)