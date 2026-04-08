import commands/commands
import error
import gleam/bytes_tree
import gleam/dict
import gleam/erlang/process
import gleam/io
import gleam/option
import gleam/otp/actor
import gleam/result
import gleam/string
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
    glisten.handler(on_connection_init, handle_connection_message)
    |> glisten.serve(6379)

  process.sleep_forever()
}

fn handle_connection_message(
  message: glisten.Message(message),
  store: store.Store,
  connection: glisten.Connection(message),
) -> actor.Next(glisten.Message(message), store.Store) {
  let assert glisten.Packet(packet) = message

  let #(response, store) = case handle_packet(packet, store) {
    Ok(#(response, store)) -> #(bytes_tree.from_bit_array(response), store)

    Error(error) -> {
      let response = error.encode(error) <> "\r\n"
      #(bytes_tree.from_string(response), store)
    }
  }

  let assert Ok(_) = glisten.send(connection, response)

  actor.continue(store)
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
  use parse_output <- result.try(
    parse.parse(packet)
    |> result.map_error(fn(error) { error.ParseError(error) }),
  )

  use #(command, arguments) <- result.try(case parse_output {
    parse.ParseOutput(data.Array([data.BulkString(command), ..arguments]), <<>>) ->
      Ok(#(string.uppercase(command), arguments))

    _ -> Error(error.InvalidRequestFormat)
  })

  use #(response, store) <- result.try(
    commands.handle(command, arguments, store)
    |> result.map_error(fn(error) { error.CommandExecutionError(error) }),
  )

  let response = encode.encode(response)

  Ok(#(response, store))
}
