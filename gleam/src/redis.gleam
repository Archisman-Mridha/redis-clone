import command/command
import error
import gleam/bytes_tree
import gleam/dict
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import glisten
import resp/data
import resp/encode
import resp/parse
import store/store

pub fn main() -> Nil {
  io.println("💫 Running Redis TCP server....")

  let store = dict.new()

  // We need to maintain some state (the store in our case) across connections.
  // And this function provides that state to each connection handler.
  let on_connection_init = fn(_connection: glisten.Connection(message)) -> #(
    store.Store,
    option.Option(process.Selector(message)),
  ) {
    #(store, option.None)
  }

  let assert Ok(_) =
    // Provides a supervisor over a pool of socket acceptors (default size = 10).
    // Each acceptor will block on accept until a connection is opened. The acceptor will then
    // spawn a handler process and then block again on accept.
    glisten.new(on_connection_init, handle_connection_message)
    |> glisten.start(6379)

  process.sleep_forever()
}

fn handle_connection_message(
  store: store.Store,
  message: glisten.Message(message),
  connection: glisten.Connection(message),
) -> glisten.Next(store.Store, glisten.Message(message)) {
  let assert glisten.Packet(packet) = message

  let #(response, store) = case handle_packet(packet, store) {
    Ok(#(response, store)) -> #(bytes_tree.from_bit_array(response), store)

    Error(e) -> {
      let response = error.encode(e) <> "\r\n"
      #(bytes_tree.from_string(response), store)
    }
  }

  let assert Ok(_) = glisten.send(connection, response)

  glisten.continue(store)
}

/// Clients send commands to a Redis server as an array of bulk strings. The first (and sometimes
/// also the second) bulk string in the array is the command's name. Subsequent elements of the
/// array are the arguments for the command.
///
/// NOTE : For now, we assume that the complete command comes in a single TCP packet.
///
/// The server replies with a RESP type. The reply's type is determined by the command's
/// implementation and possibly by the client's protocol version.
fn handle_packet(
  packet: BitArray,
  store: store.Store,
) -> Result(#(BitArray, store.Store), error.RedisError) {
  use request <- result.try(
    parse.parse(packet)
    |> result.map_error(fn(e) { error.ParseError(e) }),
  )

  use elements <- result.try(case request {
    parse.ParseOutput(data.Array(elements), <<>>) -> Ok(elements)
    _ -> Error(error.InvalidRequestFormat)
  })

  use elements <- result.try(
    elements
    |> list.fold_right(Ok([]), fn(accumulation, element) {
      case accumulation, element {
        Ok(accumulation), data.BulkString(element) ->
          Ok([element, ..accumulation])

        _, _ -> Error(error.InvalidRequestFormat)
      }
    }),
  )

  use #(command, arguments) <- result.try(case elements {
    [command, ..arguments] -> Ok(#(command, arguments))
    _ -> Error(error.InvalidRequestFormat)
  })

  use #(response, store) <- result.try(
    command.handle(command, arguments, store)
    |> result.map_error(fn(e) { error.CommandExecutionError(e) }),
  )

  let response = encode.encode(response)

  Ok(#(response, store))
}
