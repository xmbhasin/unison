``` ucm :hide
scratch/main> builtins.merge lib.builtin
```

``` unison
unique type Foo = Bar Nat
```

``` ucm :added-by-ucm
  Loading changes detected in scratch.u.

  I found and typechecked these definitions in scratch.u. If you
  do an `add` or `update`, here's how your codebase would
  change:

    ⍟ These new definitions are ok to `add`:
    
      type Foo
```

``` ucm
scratch/main> add

  ⍟ I've added these definitions:

    type Foo
```

``` unison
unique type Foo = Bar Nat Nat
```

``` ucm :added-by-ucm
  Loading changes detected in scratch.u.

  I found and typechecked these definitions in scratch.u. If you
  do an `add` or `update`, here's how your codebase would
  change:

    ⍟ These names already exist. You can `update` them to your
      new definition:
    
      type Foo
```

``` ucm
scratch/main> update

  Okay, I'm searching the branch for code that needs to be
  updated...

  Done.

scratch/main> view Foo

  type Foo = Bar Nat Nat

scratch/main> find.verbose

  1. -- #hlhjq1lf1cvfevkvb9d441kkubn0f6s43gvrd4gcff0r739vomehjnov4b3qe8506fb5bm8m5ba0sol9mbljgkk3gb2qt2u02v6i2vo
     type Foo
     
  2. -- #hlhjq1lf1cvfevkvb9d441kkubn0f6s43gvrd4gcff0r739vomehjnov4b3qe8506fb5bm8m5ba0sol9mbljgkk3gb2qt2u02v6i2vo#0
     Foo.Bar : Nat -> Nat -> Foo
     
```