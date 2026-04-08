import error
import resp/data

/// Returns PONG if no argument is provided, otherwise return a copy of the argument as a bulk.
pub fn handle(
  arguments: List(data.BulkString),
) -> Result(data.Data, error.CommandExecutionError) {
  case arguments {
    [] -> Ok(data.SimpleString("PONG"))

    [argument] -> Ok(data.BulkString(argument))

    _ -> Error(error.WrongArguments)
  }
}
