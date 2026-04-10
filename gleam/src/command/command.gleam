import command/get/handle as get
import command/ping
import command/set/handle as set
import error
import gleam/result
import resp/data
import store/store

pub fn handle(
  command: data.BulkString,
  arguments: List(data.BulkString),
  store: store.Store,
) -> Result(#(data.Data, store.Store), error.CommandExecutionError) {
  case command {
    "PING" -> {
      use response <- result.try(ping.handle(arguments))
      Ok(#(response, store))
    }

    "ECHO" -> {
      use response <- result.try(handle_echo(arguments))
      Ok(#(response, store))
    }

    // Handling commands related to Redis Strings.
    "SET" -> set.handle(arguments, store)
    "GET" -> get.handle(arguments, store)

    _ -> Error(error.UnknownCommand)
  }
}

/// Returns message.
fn handle_echo(
  arguments: List(data.BulkString),
) -> Result(data.Data, error.CommandExecutionError) {
  case arguments {
    [argument] -> Ok(data.BulkString(argument))

    _ -> Error(error.WrongArguments)
  }
}
