package command

import resp.Data
import error.CommandExecutionError

extension (c: Command)
  def echo(): Either[CommandExecutionError, Data] = {
    val message = c.arguments.nextOption() match {
      case Some(message) => message
      case None => return Left(CommandExecutionError.WrongArguments)
    }

    // Ensure that no more arguments are provided.
    if(c.arguments.hasNext) {
      return Left(CommandExecutionError.WrongArguments)
    }

    Right(message)
  }
