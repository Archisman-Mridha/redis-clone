import command/command
import gleam/dict
import gleeunit/should
import resp/data

pub fn handle_ping_command_test() {
  let store = dict.new()

  command.handle("PING", [], store)
  |> should.equal(Ok(#(data.SimpleString("PONG"), store)))
}

pub fn handle_ping_command_with_argument_test() {
  let store = dict.new()

  let argument = "HELLO"

  let expected_response = #(data.BulkString(argument), store)

  command.handle("PING", [argument], store)
  |> should.be_ok()
  |> should.equal(expected_response)
}
