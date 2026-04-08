import commands/commands
import resp/parse

pub type RedisError {
  ParseError(parse.ParseError)
  InvalidRequestFormat
  CommandExecutionError(commands.HandleError)
}

/// Returns RedisError encoded as a simple error.
///
/// RESP has specific data types for errors. Simple errors, or simply just errors, are similar to
/// simple strings, but their first character is the minus (-) character. The difference between
/// simple strings and errors in RESP is that clients should treat errors as exceptions, whereas
/// the string encoded in the error type is the error message itself.
///
/// The basic format is:
///
///                                -Error message\r\n
///
/// The following are examples of error replies:
///
///   -ERR unknown command 'asdf'
///   -WRONGTYPE Operation against a key holding the wrong kind of value
///
/// The first upper-case word after the -, up to the first space or newline, represents the kind of
/// error returned. This word is called an error prefix. Note that the error prefix is a convention
/// used by Redis rather than part of the RESP error type.
/// For example, in Redis, ERR is a generic error, whereas WRONGTYPE is a more specific error that
/// implies that the client attempted an operation against the wrong data type. The error prefix
/// allows the client to understand the type of error returned by the server without checking the
/// exact error message.
pub fn encode(error: RedisError) -> String {
  "-"
  <> case error {
    ParseError(error) ->
      case error {
        parse.UnexpectedEndOfInput ->
          "UnexpectedEndOfInput Unexpected end of input"
        parse.InvalidUTF8Character ->
          "InvalidUTF8Character Found invalid UTF8 character"
        parse.FailedParsingLength -> "FailedParsingLength Failed parsing length"
        parse.UnexpectedInput -> "UnexpectedInput Unexpected input"
      }

    InvalidRequestFormat -> "InvalidRequestFormat Invalid request format"

    CommandExecutionError(error) ->
      case error {
        commands.UnknownCommand -> "UnknownCommand Unknown command"
        commands.WrongArguments -> "WrongArguments Wrong arguments"
        commands.WrongOperationType -> "WrongOperationType Wrong operation type"
        commands.KeyNotFound -> "KeyNotFound Key not found"
      }
  }
  <> "\r\n"
}
