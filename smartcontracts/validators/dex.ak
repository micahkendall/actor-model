use aiken/transaction.{ScriptContext}
use actor_model/policy.{policy_wrapper, Transition, Terminate}

type MyDatum = ByteArray
type MyRedeemer = ByteArray

fn policy(a: MyDatum, r: MyRedeemer, s: ScriptContext) -> Transition<MyDatum> {
  Terminate
  // To { datum: MyDatum, val: Value }
}

pub fn spend(a, b, c) {
  policy_wrapper(policy, a, b, c)
}
