### Transcript parser hidden errors

When an expected error is not encountered in a `unison :hide-all :error` block
then the transcript parser should print the stanza
and surface a helpful message.

``` unison :hide-all :error
myVal = 3
```

🛑

The transcript was expecting an error in the stanza above, but did not encounter one.
