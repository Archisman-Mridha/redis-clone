use {
  crate::{command::Command, error::CommandExecutionError, resp::data::Data, store::Value},
  std::time::SystemTime
};

impl<'command> Command<'command> {
  /// Get the value of key. If the key does not exist the special value nil is returned. An error
  /// is returned if the value stored at key is not a string, because GET only handles string
  /// values.
  ///
  /// Returns one of the following:
  ///
  ///   (1) Bulk string reply: the value of the key.
  ///   (2) Nil reply: if the key does not exist.
  pub fn get(&'command mut self) -> Result<Data, CommandExecutionError> {
    let arguments = &mut self.arguments;

    let key = match (arguments.next(), arguments.next()) {
      (Some(key), None) => key,
      _ => return Err(CommandExecutionError::WrongArguments)
    };

    let store = self
      .store
      .lock()
      .map_err(|_| CommandExecutionError::ServerError)?;

    match store.get(key) {
      Some(Value::String { value, expires_at }) => match is_key_expired(expires_at) {
        false => Ok(Data::BulkString(value.to_owned())),
        _ => Err(CommandExecutionError::KeyNotFound)
      },

      None => Ok(Data::Null),

      Some(_) => Err(CommandExecutionError::WrongOperationType)
    }
  }
}

/// Returns whether a key is expired, based on the corresponding expires_at property.
fn is_key_expired(expires_at: &Option<SystemTime>) -> bool {
  expires_at.is_some_and(|expires_at| SystemTime::now() >= expires_at)
}
