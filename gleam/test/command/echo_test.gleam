import command/command
import gleam/dict
import gleeunit/should
import resp/data

pub fn handle_echo_command_test() {
  let store = dict.new()

  let argument = "HELLO"

  let expected_response = #(data.BulkString(argument), store)

  command.handle("ECHO", [argument], store)
  |> should.be_ok()
  |> should.equal(expected_response)
}
