import commands/commands
import gleam/dict
import gleeunit/should
import resp/data

pub fn handle_echo_command_test() {
  let store = dict.new()

  let argument = data.BulkString("HELLO")

  commands.handle("ECHO", [argument], store)
  |> should.equal(Ok(#(argument, store)))
}
