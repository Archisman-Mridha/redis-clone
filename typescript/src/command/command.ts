import { Effect, Match } from "effect"
import { BulkString, type TBulkString, type TData } from "../resp/data"
import type { Store } from "../store/store"
import { UnknownCommand, type CommandExecutionError } from "../error"
import { PingCommand } from "./ping"
import { EchoCommand } from "./echo"
import { SetCommand } from "./set"
import { GetCommand } from "./get"

export abstract class Command {
  constructor(
    protected readonly args: Iterator<TBulkString>,

    protected readonly store: typeof Store
  ) { }

  abstract handle( ): Effect.Effect<TData, CommandExecutionError>
}

export class CommandDispatcher {
  constructor(
    private readonly command: TBulkString,
    private readonly args: Iterator<TBulkString>,

    private readonly store: typeof Store
  ) { }

  dispatch( ): Effect.Effect<TData, CommandExecutionError> {
    return Match.value(this.command).pipe(
      Match.when(BulkString({ string: "PING" }), (_) => {
        const pingCommand = new PingCommand(this.args, this.store)
        return pingCommand.handle( )
      }),

      Match.when(BulkString({ string: "ECHO" }), (_) => {
        const echoCommand = new EchoCommand(this.args, this.store)
        return echoCommand.handle( )
      }),

      // Handling commands related to Redis Strings.
      Match.when(BulkString({ string: "SET" }), (_) => {
        const setCommand = new SetCommand(this.args, this.store)
        return setCommand.handle( )
      }),
      Match.when(BulkString({ string: "GET" }), (_) => {
        const getCommand = new GetCommand(this.args, this.store)
        return getCommand.handle( )
      }),

      Match.orElse(( ) => Effect.fail(UnknownCommand( )))
    )
  }
}
