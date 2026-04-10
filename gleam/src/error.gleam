pub type RedisError {
  ParseError(ParseError)
  InvalidRequestFormat
  CommandExecutionError(CommandExecutionError)
}

pub type ParseError {
  InvalidUTF8Character
  FailedParsingLength
  UnexpectedInput
  UnexpectedEndOfInput
}

pub type CommandExecutionError {
  UnknownCommand
  WrongArguments
  UnknownOption
  WrongOperationType
  KeyNotFound
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
    InvalidRequestFormat -> "InvalidRequestFormat Invalid request format"

    ParseError(error) ->
      case error {
        InvalidUTF8Character ->
          "InvalidUTF8Character Found invalid UTF8 character"
        FailedParsingLength -> "FailedParsingLength Failed parsing length"
        UnexpectedInput -> "UnexpectedInput Unexpected input"
        UnexpectedEndOfInput -> "UnexpectedEndOfInput Unexpected end of input"
      }

    CommandExecutionError(error) ->
      case error {
        UnknownCommand -> "UnknownCommand Unknown command"
        WrongArguments -> "WrongArguments Wrong arguments"
        UnknownOption -> "UnknownOption unknown option"
        WrongOperationType -> "WrongOperationType Wrong operation type"
        KeyNotFound -> "KeyNotFound Key not found"
      }
  }
  <> "\r\n"
}
