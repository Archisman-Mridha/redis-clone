use {
  crate::{
    command::Command,
    error::CommandExecutionError,
    resp::data::{BulkString, Data},
    store::Value
  },
  std::{slice::Iter, time}
};

impl<'command> Command<'command> {
  /// Set key to hold the string value. When key already holds a value, it is overwritten,
  /// regardless of its type. Any previous time to live associated with the key is discarded on
  /// successful SET operation.
  ///
  /// Returns the simple string : OK.
  pub fn set(&'command mut self) -> Result<Data, CommandExecutionError> {
    let arguments = &mut self.arguments;

    let (key, value) = match (arguments.next(), arguments.next()) {
      (Some(key), Some(value)) => (key.clone(), value.clone()),
      _ => return Err(CommandExecutionError::WrongArguments)
    };

    let options = OptionsParser::new(arguments).parse()?;

    let expires_at = options
      .ex
      .map(|secs| time::SystemTime::now() + time::Duration::from_secs(secs as u64));

    // NOTE : We do all the parsing before.
    //        So, we hold the mutex lock for minimal time.

    let mut store = self
      .store
      .lock()
      .map_err(|_| CommandExecutionError::ServerError)?;

    match store.get_mut(&key) {
      None | Some(Value::String { .. }) => {
        store.insert(key, Value::String { value, expires_at });
      }
      _ => return Err(CommandExecutionError::WrongOperationType)
    }

    let response = Data::SimpleString(String::from("OK"));
    Ok(response)
  }
}

#[derive(Default)]
struct Options {
  /// Set the specified expire time, in seconds (a positive integer).
  ex: Option<usize>
}

struct OptionsParser<'options_parser> {
  options:   Options,
  arguments: &'options_parser mut Iter<'options_parser, BulkString>
}

impl<'options_parser> OptionsParser<'options_parser> {
  fn new(arguments: &'options_parser mut Iter<'options_parser, BulkString>) -> Self {
    Self {
      options: Options::default(),
      arguments
    }
  }

  fn parse(&mut self) -> Result<Options, CommandExecutionError> {
    #[allow(clippy::while_let_loop)]
    loop {
      match self.arguments.next() {
        Some(name) => match name.as_str() {
          "EX" => self.parse_ex()?,

          _ => return Err(CommandExecutionError::UnknownOption)
        },
        _ => break
      }
    }

    let options = std::mem::take(&mut self.options);
    Ok(options)
  }

  fn parse_ex(&mut self) -> Result<(), CommandExecutionError> {
    let ex = self
      .arguments
      .next()
      .ok_or(CommandExecutionError::WrongArguments)?;

    self.options.ex = Some(
      ex.parse::<usize>()
        .map_err(|_| CommandExecutionError::WrongArguments)?
    );

    Ok(())
  }
}
