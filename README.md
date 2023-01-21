# Actor Model in Cardano


Implementing [plutus-specification-language/Actor-Model-Cardano](https://github.com/mlabs-haskell/plutus-specification-language/blob/d580308922802c668b46d9afab1c808d9c9191c9/Actor-Model-Cardano.md)

<!-- We provide library functions for the actions `Terminate, Send, Receive, Take` which can be used to implement an actor instance through parameterization. Later we intend to show a version without parameterization (using actor factories.) -->

Factory policy should ensure that each minted value is unique, to the control script, and has a correct datum encoding (InstanceDatum.Actor).

Actor instances are UTXOs with a unique token from some factory policy, the actor datum and are at the control script. The asset name is the instance id, it is the onus of the mint policy to ensure uniqueness, we assume that is ensured.

Spend, Receive, Take are helper functions to enforce.
Termination is invoked by returning None in the optional datum of step, forces burn of the instance token and has no restriction on expected output value.
Internally, if termination is not returned, the non-termination helper is invoked.

Messages are also UTXO at the policy address, have no required asset, and have a different datum (InstanceDatum.Message). Our policy allows them to be spent in any TX where their recipient instance is also spent.

todo:

- Fix non-compile
- Allow spend messages (message dependent on receiving script being invoked)
- Composable send/receive/take functions.
- Flesh out dex example (liquidity pool)
- Cabalify the top level of this repo, bring in plutip, add app dir, and add some basic tests.
- Plutarch implementation

For send/receive/take I am thinking of a ScriptContext-like structure where you have a list of TxIn & TxOut, and an accumulating 'Value'.
[TxIn],[TxOut] are copied from scriptcontext, receive removes from TxIn, send removes from TxOut,
there is a final check that there are no unreceived (messages you don't intend to receive) messages in TxIn, no unsent (messages you don't intend to send) messages in TxOut,
and also a value check to ensure that the total change in value from one transition to another is exactly the sum of old_value+received-sent+take