import { DateTime, Effect, Match, MutableHashMap, Option } from "effect"
import { CommandExecutionError, WrongArguments, WrongOperationType } from "../error"
import { BulkString, Null, type TData } from "../resp/data"
import { Command } from "./command"

export class GetCommand extends Command {
  /*
    Get the value of key. If the key does not exist the special value nil is returned. An error
    is returned if the value stored at key is not a string, because GET only handles string
    values.

    Returns one of the following:

      (1) Bulk string reply: the value of the key.
      (2) Nil reply: if the key does not exist.
  */
  override handle( ): Effect.Effect<TData, CommandExecutionError> {
    const key = this.args.next()
    if(!key.done)
      return Effect.fail(WrongArguments())

    // Ensure that no more arguments are provided.
    if(!this.args.next( ).done)
      return Effect.fail(WrongArguments( ))

    const value = MutableHashMap.get(this.store, key.value.string)

    return Option.match(value, {
      onNone: ( ) => Effect.succeed(Null()),

      onSome: (value) => Match.value(value).pipe(
        Match.when({ _tag: "String" }, string => {
          const is_key_expired = Option.match(string.expires_at, {
            onNone: ( ) => false,

            onSome: expires_at => DateTime.greaterThanOrEqualTo(DateTime.unsafeNow(), expires_at)
          })

          if(is_key_expired)
            return Effect.succeed(Null())

          return Effect.succeed(BulkString({ string: string.string }))
        }),

        Match.orElse(( ) => Effect.fail(WrongOperationType()))
      )
    })
  }
}
