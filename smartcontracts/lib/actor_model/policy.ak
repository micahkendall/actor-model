use aiken/transaction.{ScriptContext, Spend, Output, InlineDatum}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName}

pub type Transition<b> {
  Terminate
  To { datum: b, val: Value }
}

pub type InstanceDatum<datum_type, message_type> {
  Actor { asset: (ByteArray, ByteArray), datum: datum_type }
  Message { recipient: Address, content: message_type }
}

pub type InnerValueDict {
  inner: List<(AssetName, Int)>
}

pub type ValueDict {
  inner: List<(ByteArray, InnerValueDict)>
}

pub type Value {
  Value {inner: ValueDict}
}
fn force_as_value(x: Data)->Value{
  x
}

// type Send<message_type> {
//   // Send to recipient, amount val, with message content
//   recipient: Address,
//   val: Value,redeclaring 
//   val: Value,
//   content: message_type,
// }

// type Take {
//   what: Value,
// }

fn unsafe_where(self: List<a>, p: fn(a) -> Bool) -> a {
  when self is {
    [] -> error()
    [x, ..xs] ->
      if p(x) {
        x
      } else {
        unsafe_where(xs, p)
      }
  }
}

fn unsafe_any(self: List<a>, p: fn(a) -> Bool) -> Bool {
  when self is {
    [] -> error()
    [x, ..xs] -> p(x) || unsafe_any(xs, p)
  }
}

// enforce that asset was burnt
fn terminate(a: (ByteArray, ByteArray), s: ScriptContext) -> Bool {
  when a is {
    (j, k)->{
      let mintedd: Data = s.transaction.mint
      let minted: Value = mintedd
      unsafe_any(minted.inner.inner, fn(b: (ByteArray, InnerValueDict)) {
        when b is {
          (u, dic) -> {
            u == j && {
              unsafe_any(dic.inner, fn(c: (ByteArray, Int)) {
                when c is {
                  (e,r)->e==k && r==-1
                }
              })
            }
          }
        }
      })
    }
    _->False
  }
}

// enforce there is some output with both newdatum and newvalue at output.
fn nonterminate(
  this: Address,
  newdatum: InstanceDatum<datum_type, message_type>,
  newvalue: Value,
  s: ScriptContext
) -> Bool {
  unsafe_any(s.transaction.outputs, fn (o: Output) {
    o.address == this && force_as_value(o.value) == newvalue && o.datum == InlineDatum(newdatum)
  })
}

pub fn policy_wrapper(
  step: fn(a, redeemer_type, ScriptContext) -> Transition<a>,
  d: InstanceDatum<a, c>,
  r: redeemer_type,
  s: ScriptContext,
) -> Bool {
  let this_address =
    unsafe_where(
      s.transaction.inputs,
      fn(a) {
        when s.purpose is {
          Spend(x) -> x == a.output_reference
          _ -> error()
        }
      },
    ).output.address
  when d is {
    Actor(asset, datum) ->
      when step(datum, r, s) is {
        To(d2, v2) -> nonterminate(this_address, Actor(asset, d2), v2, s)
        Terminate -> terminate(asset, s)
        _ -> error()
      }
    Message(_, _) -> error()
  }
}