import commands/commands
import gleeunit/should
import resp/data

pub fn handle_ping_command_test() {
  commands.handle("PING", [])
  |> should.equal(Ok(data.SimpleString("PONG")))
}

pub fn handle_ping_command_with_argument_test() {
  let argument = data.BulkString("HELLO")

  commands.handle("PING", [argument])
  |> should.equal(Ok(argument))
}
