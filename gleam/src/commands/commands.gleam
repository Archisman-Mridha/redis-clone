import resp/data

pub type HandleError {
  WrongArgumentCount
  UnknownCommand
}

pub fn handle(
  command: String,
  arguments: List(data.Data),
) -> Result(data.Data, HandleError) {
  case command {
    "PING" -> handle_ping(arguments)

    "ECHO" -> handle_echo(arguments)

    _ -> Error(UnknownCommand)
  }
}

// Returns PONG if no argument is provided, otherwise return a copy of the argument as a bulk.
fn handle_ping(arguments: List(data.Data)) -> Result(data.Data, HandleError) {
  case arguments {
    [] -> Ok(data.SimpleString("PONG"))

    [data.BulkString(argument)] -> Ok(data.BulkString(argument))

    _ -> Error(WrongArgumentCount)
  }
}

// Returns message.
fn handle_echo(arguments: List(data.Data)) -> Result(data.Data, HandleError) {
  case arguments {
    [data.BulkString(argument)] -> Ok(data.BulkString(argument))

    _ -> Error(WrongArgumentCount)
  }
}
