import commands/commands
import error
import gleam/bytes_tree
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

pub fn main() -> Nil {
  io.println("💫 Running Redis TCP server....")

  let assert Ok(_) =
    // Provides a supervisor over a pool of socket acceptors (default size = 10).
    // Each acceptor will block on accept until a connection is opened. The acceptor will then
    // spawn a handler process and then block again on accept.
    glisten.handler(on_connection_init, handle_connection_message)
    |> glisten.serve(6379)

  process.sleep_forever()
}

fn on_connection_init(
  _connection: glisten.Connection(message),
) -> #(Nil, option.Option(process.Selector(message))) {
  #(Nil, option.None)
}

fn handle_connection_message(
  message: glisten.Message(message),
  state,
  connection: glisten.Connection(message),
) -> actor.Next(glisten.Message(message), data) {
  let assert glisten.Packet(packet) = message

  let assert Ok(_) = case handle_packet(packet) {
    Ok(response) ->
      glisten.send(connection, bytes_tree.from_bit_array(response))

    Error(error) -> {
      let response = string.append("ERROR : ", error.to_error_message(error))
      glisten.send(connection, bytes_tree.from_string(response))
    }
  }

  actor.continue(state)
}

// Clients send commands to a Redis server as an array of bulk strings. The first (and sometimes
// also the second) bulk string in the array is the command's name. Subsequent elements of the
// array are the arguments for the command.
//
// NOTE : For now, we assume that the complete command comes in a single TCP packet.
//
// The server replies with a RESP type. The reply's type is determined by the command's
// implementation and possibly by the client's protocol version.
fn handle_packet(packet: BitArray) -> Result(BitArray, error.RedisError) {
  use parse_output <- result.try(
    parse.parse(packet)
    |> result.map_error(fn(error) { error.ParseError(error) }),
  )

  use #(command, arguments) <- result.try(case parse_output {
    parse.ParseOutput(data.Array([data.BulkString(command), ..arguments]), <<>>) ->
      Ok(#(string.uppercase(command), arguments))

    _ -> Error(error.InvalidRequestFormat)
  })

  use response <- result.try(
    commands.handle(command, arguments)
    |> result.map_error(fn(error) { error.CommandExecutionError(error) }),
  )

  Ok(encode.encode(response))
}
