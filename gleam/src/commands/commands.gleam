import gleam/dict
import gleam/result
import resp/data
import store/store

pub type HandleError {
  WrongArguments
  UnknownCommand
  WrongOperationType
  KeyNotFound
}

pub fn handle(
  command: String,
  arguments: List(data.Data),
  store: store.Store,
) -> Result(#(data.Data, store.Store), HandleError) {
  case command {
    "PING" -> {
      use response <- result.try(handle_ping(arguments))
      Ok(#(response, store))
    }

    "ECHO" -> {
      use response <- result.try(handle_echo(arguments))
      Ok(#(response, store))
    }

    // Related to Redis Strings.
    "SET" -> handle_set(arguments, store)
    "GET" -> handle_get(arguments, store)

    _ -> Error(UnknownCommand)
  }
}

/// Returns PONG if no argument is provided, otherwise return a copy of the argument as a bulk.
fn handle_ping(arguments: List(data.Data)) -> Result(data.Data, HandleError) {
  case arguments {
    [] -> Ok(data.SimpleString("PONG"))

    [data.BulkString(argument)] -> Ok(data.BulkString(argument))

    _ -> Error(WrongArguments)
  }
}

/// Returns message.
fn handle_echo(arguments: List(data.Data)) -> Result(data.Data, HandleError) {
  case arguments {
    [data.BulkString(argument)] -> Ok(data.BulkString(argument))

    _ -> Error(WrongArguments)
  }
}

/// Set key to hold the string value. When key already holds a value, it is overwritten, regardless
/// of its type. Any previous time to live associated with the key is discarded on successful SET
/// operation.
///
/// Returns the simple string : OK.
fn handle_set(
  arguments: List(data.Data),
  store: store.Store,
) -> Result(#(data.Data, store.Store), HandleError) {
  use #(key, value) <- result.try(case arguments {
    [data.BulkString(key), data.BulkString(value)] -> Ok(#(key, value))

    _ -> Error(WrongArguments)
  })

  case dict.get(store, key) {
    Error(_) | Ok(store.String(_)) -> {
      let store = dict.insert(store, key, store.String(value))
      Ok(#(data.SimpleString("OK"), store))
    }

    Ok(_) -> Error(WrongOperationType)
  }
}

/// Get the value of key. If the key does not exist the special value nil is returned. An error is
/// returned if the value stored at key is not a string, because GET only handles string values.
///
/// Returns one of the following:
///
///   (1) Bulk string reply: the value of the key.
///   (2) Nil reply: if the key does not exist.
fn handle_get(
  arguments: List(data.Data),
  store: store.Store,
) -> Result(#(data.Data, store.Store), HandleError) {
  use key <- result.try(case arguments {
    [data.BulkString(key)] -> Ok(key)
    _ -> Error(WrongArguments)
  })

  use response <- result.try(case dict.get(store, key) {
    Error(_) -> Ok(data.Null)

    Ok(store.String(value)) -> Ok(data.BulkString(value))

    Ok(_) -> Error(WrongOperationType)
  })

  Ok(#(response, store))
}
