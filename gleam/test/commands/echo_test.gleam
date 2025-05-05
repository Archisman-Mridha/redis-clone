import commands/commands
import gleeunit/should
import resp/data

pub fn handle_echo_command_test() {
  let argument = data.BulkString("HELLO")

  commands.handle("ECHO", [argument])
  |> should.equal(Ok(argument))
}
