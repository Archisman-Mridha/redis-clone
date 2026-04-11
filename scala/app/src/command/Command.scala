package command

import store.Store
import resp.Data
import error.CommandExecutionError

class Command(
  val command: Data.BulkString,
  val arguments: scala.Iterator[Data.BulkString],
  val store: Store
):
  def handle(): Either[CommandExecutionError, Data] = {
    command.string match
      case "PING" => this.ping()

      case "ECHO" => this.echo()

      // Handling commands related to Redis Strings.
      case "SET" => this.set()
      case "GET" => this.get()

      case _ => Left(CommandExecutionError.UnknownCommand)
  }
