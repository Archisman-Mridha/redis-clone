import { Effect } from "effect"
import { Command } from "./command"
import { WrongArguments, type CommandExecutionError } from "../error"
import { BulkString, type TData } from "../resp/data"

export class PingCommand extends Command {
  override handle( ): Effect.Effect<TData, CommandExecutionError> {
    const messageOption = this.args.next( )

    const message = !messageOption.done
      ? messageOption.value
      : BulkString({ string: "PONG" })

    // Ensure that no more arguments are provided.
    if(!this.args.next( ).done)
      return Effect.fail(WrongArguments( ))

    return Effect.succeed(message)
  }
}
