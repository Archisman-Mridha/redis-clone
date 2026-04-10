#[derive(Debug)]
pub enum RedisError {
  InvalidRequestFormat,
  ParseError(ParseError),
  CommandExecutionError(CommandExecutionError)
}

#[derive(Debug)]
pub enum ParseError {
  UnexpectedError,

  InvalidUTF8Character,
  FailedParsingLength,
  UnexpectedInput,
  UnexpectedEndOfInput
}

#[derive(Debug)]
pub enum CommandExecutionError {
  ServerError,

  UnknownCommand,
  WrongArguments,
  UnknownOption,
  WrongOperationType,
  KeyNotFound
}

impl RedisError {
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
  /// The first upper-case word after the -, up to the first space or newline, represents the kind
  /// of error returned. This word is called an error prefix. Note that the error prefix is a
  /// convention used by Redis rather than part of the RESP error type.
  /// For example, in Redis, ERR is a generic error, whereas WRONGTYPE is a more specific error that
  /// implies that the client attempted an operation against the wrong data type. The error prefix
  /// allows the client to understand the type of error returned by the server without checking the
  /// exact error message.
  pub fn encode(&self) -> String {
    let encoding = match self {
      Self::InvalidRequestFormat => "InvalidRequestFormat Invalid request format",

      Self::ParseError(error) => match error {
        ParseError::UnexpectedError => "UnexpectedError Unexpected error",
        ParseError::InvalidUTF8Character => "InvalidUTF8Character Found invalid UTF8 character",
        ParseError::FailedParsingLength => "FailedParsingLength Failed parsing length",
        ParseError::UnexpectedInput => "UnexpectedInput Unexpected input",
        ParseError::UnexpectedEndOfInput => "UnexpectedEndOfInput Unexpected end of input"
      },

      Self::CommandExecutionError(error) => match error {
        CommandExecutionError::ServerError => "ServerError Server error",
        CommandExecutionError::UnknownCommand => "UnknownCommand Unknown command",
        CommandExecutionError::WrongArguments => "WrongArguments Wrong arguments",
        CommandExecutionError::UnknownOption => "UnknownOption unknown option",
        CommandExecutionError::WrongOperationType => "WrongOperationType Wrong operation type",
        CommandExecutionError::KeyNotFound => "KeyNotFound Key not found"
      }
    };

    let encoding = format!("-{encoding}\r\n");
    encoding
  }
}
