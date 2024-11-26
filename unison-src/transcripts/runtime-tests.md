# An assortment of regression tests that exercise various interesting cases within the runtime.

```ucm:hide
scratch/main> builtins.merge lib.builtins
```


```unison
negativeCaseMatch = match -10 with
  +1 -> "bad"
  -10 -> "good"
  +3 -> "bad"
  _ -> "bad"
> negativeCaseMatch

funcWithMoreThanTwoUnboxedArgs : Nat -> Nat -> Nat -> Nat
funcWithMoreThanTwoUnboxedArgs x y z =
  x + y + z

> funcWithMoreThanTwoUnboxedArgs 1 2 3

funcWithMixedArgTypes : Nat -> Text -> Nat -> Text
funcWithMixedArgTypes x y z =
  Nat.toText x ++ y ++ Nat.toText z

> funcWithMixedArgTypes 1 "hello" 2

unboxedAndBoxedArgsInSequences = ([1, 2, 3], ["x", "y", "z"])
> unboxedAndBoxedArgsInSequences

casting = (Nat.toInt 100,
           Float.toRepresentation 3.14,
           Float.fromRepresentation 4614253070214989087,
           Int.fromRepresentation 100,
           Int.toRepresentation +10,
           Int.toRepresentation -10)
> casting


> 1 Universal.== Int.toRepresentation +1
> [1, 2, 3] Universal.== [Int.toRepresentation +1, Int.toRepresentation +2, Int.toRepresentation +3]

-- Float edge cases
> compare 0.0 0.0
> compare +0.0 (-0.0)
> compare -0.0 (+0.0)
> compare -1.0 1.0

-- Currently, the same NaN's are equal, but different NaN's are not...
>  (0.0/0.0) == (0.0/0.0)
>  (0.0/0.0) == (1.0/0.0)

> Universal.compare [] [1]
> Universal.compare [1, 2] [2, 3]
> Universal.compare [2, 3] [1, 2]

-- Values in 'Any' are compared a bit strangely.
-- Currently we have special-cases to compare the values of Nats and Ints directly, ignoring their type, for better or
-- worse.
-- This helps to counter a different issue we have, where `load (save +10)` will load a `Nat` runtime type rather than
-- an Int, since we don't actually store the type of numerics in the ANF.Value type.
> Universal.compare (Any [1, 2]) (Any [+1, +2])

-- Regression test for a problem with universalCompare where Nats larger than maxInt would compare incorrectly, but only
-- when nested within other types due to how lists of constructor fields were compared.
> Universal.compare (1,()) (18446744073709551615, ())

-- Types in tuples should compare one by one left-to-right
> Universal.compare (1, "", 2) (1, "", 3)
> Universal.compare (1, "", 3) (1, "", 2)
```