import command/set/options
import error
import gleam/dict
import gleam/option
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import resp/data
import store/store

/// Set key to hold the string value. When key already holds a value, it is overwritten, regardless
/// of its type. Any previous time to live associated with the key is discarded on successful SET
/// operation.
///
/// Returns the simple string : OK.
pub fn handle(
  arguments: List(data.BulkString),
  store: store.Store,
) -> Result(#(data.Data, store.Store), error.CommandExecutionError) {
  use #(key, value, options) <- result.try(case arguments {
    [key, value, ..options] -> Ok(#(key, value, options))

    _ -> Error(error.WrongArguments)
  })

  use options <- result.try(options.parse(options, options.new()))

  case dict.get(store, key) {
    Error(_) | Ok(store.String(..)) -> {
      let expires_at =
        options.ex
        |> option.map(fn(ex) {
          timestamp.system_time() |> timestamp.add(duration.seconds(ex))
        })

      let store = dict.insert(store, key, store.String(value, expires_at))
      Ok(#(data.SimpleString("OK"), store))
    }

    Ok(_) -> Error(error.WrongOperationType)
  }
}
