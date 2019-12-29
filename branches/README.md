# Dangerously Set Inner Bernoulli Gate

This script is part of a series of [Monome crow](https://monome.org/docs/crow/) related scripts.
It's provided _as-is_ and for various reasons is not meant to work out of the box.

### -- sentence --
The Dangerously Set Inner Bernoulli Gate takes two (mostly alternating) gate signals, evaluates them over each other and across time, to generate presumably interesting (and somewhat predictable) patterns.

Imagine four logical outputs asking questions to an [MI Branches](https://mutable-instruments.net/modules/branches), everytime it produces a gate. 
Is output A being triggered, or B? Is it the 2nd time it plays? Is output 3 about to play? Is it the sequence's 7th step?

### -- grammar --
in order to generate these four sequences, each logical output is assigned a table of conditions that define whether or not an incoming gate signal should be forwarded to its corresponding physical output or not.

```lua
logicalOutputs = {
  { ifInput(1), ifStep(1, 7) },
  { ifInput(2), ifStep(3, 7) },
  { ifPrevOutput(2), ifNotOutput(1) },
  { ifPrevInput(1) }
}
```
These four logical outputs are tested everytime a gate comes in. More precisely, their own, custom set of conditions is scanned and ran independently. At any time, if any of these conditions is met (returns _true_), a pulse is forwarded to the corresponding output.

In other words, _these logical outputs react to previous, incoming or future signals_. Their response is somewhat predictable, but hard to guess in an forever changing, unenven distribution of signals. Everytime one of their condition is met, they forward a gate - or not, depending on which _conjunction_ was set...

### -- verbs --
In itself, a logical output is a set of primitive tests used to create complex, intricated conditions. Mixed, they become a logical mayhem. It sometimes results in interesting patterns. 

List of these primitive tests:

*`ifInput(i:number[1-2])`*
Forwards input `i` gate state

*`ifNotInput(i)`*
Inverts `ifInput` boolean result

*`ifPrevInput(i)`*
Forwards past input `i` gate state

*`ifNotPrevInput(i)`*
Inverts `ifPrevInput` boolean result

*`ifStep(n:number[1-SIGNATURE], ...)`*
Creates a gate on a given step, inside the sequence. Takes a variable number of arguments (steps). `SIGNATURE` is a constant that defines the length of a sequence (defaults to `8`).

*`ifNotStep(n, ...)`*
Inverts `ifStep` boolean result

*`ifOutput(o:number[1-4])`*
Forwards a sibling gate state. If test is made on a previous sibling (eg. output 3 testing output 1), forwards its incoming gate state. If made on a following sibling, returns its previous gate state.

*`ifNotOutput(o)`*
Inverts `ifOutput` boolean result

### -- conjunctions --
Conjunctions are logical operators. They take the table of results of a logical output and ultimately decide to forward a pulse or do nothing.

-- `OR` --
_OR cuts across it_. If any of the tests returns _true_, returns _true_.

-- `AND` --
_OR gets across it_. If each of the tests returns _true_, returns _true_.

-- `MOST`--
_OR navigates through it_. If most of the tests returns _true_, returns _true_.

Defaults to OR.

### -- todo --

- Add methods `inContiguousRange`, `inSequenceRange`, `rand`, `rand1`
- Add a `required` property to test methods. it should set a logical output to false if condition is unmet
- Make the whole script actually work with Crow..
- Provide examples of interesting logical outputs
