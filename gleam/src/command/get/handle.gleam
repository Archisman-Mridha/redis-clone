import error
import gleam/dict
import gleam/option
import gleam/order
import gleam/result
import gleam/time/timestamp
import resp/data
import store/store

/// Get the value of key. If the key does not exist the special value nil is returned. An error is
/// returned if the value stored at key is not a string, because GET only handles string values.
///
/// Returns one of the following:
///
///   (1) Bulk string reply: the value of the key.
///   (2) Nil reply: if the key does not exist.
pub fn handle(
  arguments: List(data.BulkString),
  store: store.Store,
) -> Result(#(data.Data, store.Store), error.CommandExecutionError) {
  use key <- result.try(case arguments {
    [key] -> Ok(key)
    _ -> Error(error.WrongArguments)
  })

  use response <- result.try(case dict.get(store, key) {
    Error(_) -> Ok(data.Null)

    Ok(store.String(value, expires_at)) ->
      Ok(case is_key_expired(expires_at) {
        False -> data.BulkString(value)
        _ -> data.Null
      })

    Ok(_) -> Error(error.WrongOperationType)
  })

  Ok(#(response, store))
}

/// Returns whether a key is expired, based on the corresponding expires_at property.
fn is_key_expired(expires_at: option.Option(timestamp.Timestamp)) -> Bool {
  case expires_at {
    option.Some(expires_at) -> {
      let now = timestamp.system_time()
      timestamp.compare(now, expires_at) != order.Lt
    }

    _ -> False
  }
}
