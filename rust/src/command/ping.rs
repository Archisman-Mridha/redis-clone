use crate::{command::Command, error::CommandExecutionError, resp::data::Data};

impl Command<'_> {
  /// Returns PONG if no argument is provided, otherwise return a copy of the argument as a bulk.
  pub fn ping(&mut self) -> Result<Data, CommandExecutionError> {
    let message = match self.arguments.as_slice() {
      [message] => message,
      [] => "PONG",

      _ => return Err(CommandExecutionError::WrongArguments)
    };

    let response = Data::BulkString(String::from(message));
    Ok(response)
  }
}
