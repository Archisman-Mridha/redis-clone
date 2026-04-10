package command

import error.CommandExecutionError
import resp.Data

extension (c: Command)
  def ping(): Either[CommandExecutionError, Data] = {
    val message = c.arguments.nextOption().getOrElse(Data.BulkString("PONG"))

    // Ensure that no more arguments are provided.
    if(c.arguments.hasNext) {
      return Left(CommandExecutionError.WrongArguments)
    }

    Right(message)
  }
