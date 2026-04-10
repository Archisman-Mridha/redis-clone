package error

enum Error:
  case InvalidRequestFormat
  case Parse(error: ParseError)
  case CommandExecution(error: CommandExecutionError)

  override def toString(): String =
    this match
      case InvalidRequestFormat => "InvalidRequestFormat Invalid request format"

      case Parse(error) => error match
        case ParseError.UnexpectedError =>  "UnexpectedError Unexpected error"
        case ParseError.InvalidUTF8Character => "InvalidUTF8Character Found invalid UTF8 character"
        case ParseError.FailedParsingLength => "FailedParsingLength Failed parsing length"
        case ParseError.UnexpectedInput => "UnexpectedInput Unexpected input"
        case ParseError.UnexpectedEndOfInput => "UnexpectedEndOfInput Unexpected end of input"

      case CommandExecution(error) => error match
        case CommandExecutionError.ServerError => "ServerError Server error"
        case CommandExecutionError.UnknownCommand => "UnknownCommand Unknown command"
        case CommandExecutionError.WrongArguments => "WrongArguments Wrong arguments"
        case CommandExecutionError.UnknownOption => "UnknownOption unknown option"
        case CommandExecutionError.WrongOperationType => "WrongOperationType Wrong operation type"
        case CommandExecutionError.KeyNotFound => "KeyNotFound Key not found"

  /*
    Returns RedisError encoded as a simple error.

    RESP has specific data types for errors. Simple errors, or simply just errors, are similar to
    simple strings, but their first character is the minus (-) character. The difference between
    simple strings and errors in RESP is that clients should treat errors as exceptions, whereas
    the string encoded in the error type is the error message itself.

    The basic format is:

                                  -Error message\r\n

    The following are examples of error replies:

      -ERR unknown command 'asdf'
      -WRONGTYPE Operation against a key holding the wrong kind of value

    The first upper-case word after the -, up to the first space or newline, represents the kind
    of error returned. This word is called an error prefix. Note that the error prefix is a
    convention used by Redis rather than part of the RESP error type.
    For example, in Redis, ERR is a generic error, whereas WRONGTYPE is a more specific error that
    implies that the client attempted an operation against the wrong data type. The error prefix
    allows the client to understand the type of error returned by the server without checking the
    exact error message.
  */
  def encode(): String=
    val asString = this.toString()

    val encoding = s"- $asString\r\n"
    encoding

enum ParseError:
  case UnexpectedError,

       InvalidUTF8Character,
       FailedParsingLength,
       UnexpectedInput,
       UnexpectedEndOfInput

enum CommandExecutionError:
  case ServerError,

       UnknownCommand,
       WrongArguments,
       UnknownOption,
       WrongOperationType,
       KeyNotFound
