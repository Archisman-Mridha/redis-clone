use crate::{command::Command, error::CommandExecutionError, resp::data::Data};

impl Command<'_> {
  /// Returns message.
  pub fn echo(&mut self) -> Result<Data, CommandExecutionError> {
    let message = match self.arguments.as_slice() {
      [message] => message,
      _ => return Err(CommandExecutionError::WrongArguments)
    };

    let response = Data::BulkString(String::from(message));
    Ok(response)
  }
}
