import commands/commands
import gleam/dict
import gleeunit/should
import resp/data

pub fn handle_ping_command_test() {
  let store = dict.new()

  commands.handle("PING", [], store)
  |> should.equal(Ok(#(data.SimpleString("PONG"), store)))
}

pub fn handle_ping_command_with_argument_test() {
  let store = dict.new()

  let argument = data.BulkString("HELLO")

  commands.handle("PING", [argument], store)
  |> should.equal(Ok(#(argument, store)))
}
