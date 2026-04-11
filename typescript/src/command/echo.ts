import { Effect } from "effect"
import { Command } from "./command"
import { WrongArguments, type CommandExecutionError } from "../error"
import type { TData } from "../resp/data"

export class EchoCommand extends Command {
  override handle( ): Effect.Effect<TData, CommandExecutionError> {
    const message = this.args.next( )
    if(message.done)
      return Effect.fail(WrongArguments( ))

    // Ensure that no more arguments are provided.
    if(!this.args.next( ).done)
      return Effect.fail(WrongArguments( ))

    return Effect.succeed(message.value)
  }
}
