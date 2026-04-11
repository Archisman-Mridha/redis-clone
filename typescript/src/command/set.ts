import { DateTime, Effect, Match, MutableHashMap, Option, Schema } from "effect"
import { UnknownOption, WrongArguments, WrongOperationType, type CommandExecutionError } from "../error"
import { SimpleString, type TBulkString, type TData } from "../resp/data"
import { String as StringValue } from "../store/store"
import { Command } from "./command"

export class SetCommand extends Command {
  /*
    Set key to hold the string value. When key already holds a value, it is overwritten,
    regardless of its type. Any previous time to live associated with the key is discarded on
    successful SET operation.

    Returns the simple string : OK.
  */
  override handle( ): Effect.Effect<TData, CommandExecutionError> {
    return Effect.gen(this, function* ( ) {
      const key = this.args.next( )
      if(key.done)
        yield* Effect.fail(WrongArguments( ))

      const newValue = this.args.next( )
      if(newValue.done)
        yield* Effect.fail(WrongArguments( ))

      const existingValue = MutableHashMap.get(this.store, key.value)
      yield* Option.match(existingValue, {
        onNone: ( ) => Effect.void,
        onSome: existingValue => {
          if(existingValue._tag !== "String")
            return Effect.fail(WrongOperationType( ))

          return Effect.void
        }
      })

      const { ex } = yield* new OptionsParser(this.args).parse( )

      const expires_at = Option.map(ex, seconds =>
        DateTime.add(DateTime.unsafeNow( ), { seconds })
      )

      MutableHashMap.set(this.store, key.value, StringValue({
        string: newValue.value,
        expires_at
      }))

      return SimpleString({ string: "OK" })
    })
  }
}

const Options = Schema.Struct({
  // Set the specified expire time, in seconds (a positive integer).
  ex: Schema.Option(Schema.Number)
})

type Options = Schema.Schema.Type<typeof Options>

class OptionsParser {
  constructor(private readonly args: Iterator<TBulkString>) { }

  parse( ): Effect.Effect<Options, CommandExecutionError> {
    return Effect.gen(this, function* ( ) {
      let options: Options = {
        ex: Option.none( )
      }

      let option = this.args.next( )
      while (!option.done) {
        const ex = yield* Match.value(option.value.string.toUpperCase( )).pipe(
          Match.when("EX", ( ) => this.parseEx( )),

          Match.orElse(( ) => Effect.fail(UnknownOption( )))
        )

        options = { ...options, ex }

        option = this.args.next( )
      }

      return options
    })
  }

  private parseEx( ): Effect.Effect<Option.Option<number>, CommandExecutionError> {
    const seconds = this.args.next( )
    if(seconds.done)
      return Effect.fail(WrongArguments( ))

    const n = parseInt(seconds.value.string)
    if(isNaN(n) || n <= 0)
      return Effect.fail(WrongArguments( ))

    return Effect.succeed(Option.some(n))
  }
}
