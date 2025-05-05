import commands/commands
import resp/parse

pub type RedisError {
  ParseError(parse.ParseError)
  InvalidRequestFormat
  CommandExecutionError(commands.HandleError)
}

pub fn to_error_message(error: RedisError) -> String {
  case error {
    ParseError(error) ->
      case error {
        parse.UnexpectedEndOfInput -> "Unexpected end of input"

        // TODO : Report position.
        parse.InvalidUTF8Character -> "Found invalid UTF8 character"
        parse.FailedParsingLength -> "Failed parsing length"
        parse.UnexpectedInput -> "Unexpected input"
      }

    InvalidRequestFormat ->
      "
Invalid request format.

Clients send commands to a Redis server as an array of bulk strings. The first (and sometimes
also the second) bulk string in the array is the command's name. Subsequent elements of the
array are the arguments for the command.

NOTE : For now, we assume that the complete command comes in a single TCP packet.
      "

    CommandExecutionError(error) ->
      case error {
        commands.UnknownCommand -> "Unknown command"
        commands.WrongArgumentCount -> "Wrong argument count"
      }
  }
}
