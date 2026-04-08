import error
import gleam/int
import gleam/option
import gleam/result
import resp/data

pub type Options {
  Options(
    /// Set the specified expire time, in seconds (a positive integer).
    ex: option.Option(Int),
  )
}

pub fn new() -> Options {
  Options(ex: option.None)
}

pub fn parse(
  arguments: List(data.BulkString),
  options: Options,
) -> Result(Options, error.CommandExecutionError) {
  case arguments {
    [] -> Ok(options)

    [argument, ..remaining] -> {
      use #(options, remaining) <- result.try(case argument {
        "EX" -> parse_ex(remaining, options)

        _ -> Error(error.UnknownOption)
      })

      parse(remaining, options)
    }
  }
}

fn parse_ex(
  arguments: List(data.BulkString),
  options: Options,
) -> Result(#(Options, List(data.BulkString)), error.CommandExecutionError) {
  case arguments {
    [ex, ..remaining] -> {
      use ex <- result.try(case int.parse(ex) {
        Ok(ex) if ex > 0 -> Ok(ex)
        _ -> Error(error.WrongArguments)
      })

      let options = Options(..options, ex: option.Some(ex))

      Ok(#(options, remaining))
    }

    _ -> Error(error.WrongArguments)
  }
}
