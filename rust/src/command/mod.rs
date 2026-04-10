mod echo;
mod get;
mod ping;
mod set;

use {
  crate::{
    error::CommandExecutionError,
    resp::data::{BulkString, Data},
    store::Store
  },
  std::{
    slice,
    sync::{Arc, Mutex}
  }
};

pub struct Command<'command> {
  store: Arc<Mutex<Store>>,

  command:   BulkString,
  arguments: slice::Iter<'command, BulkString>
}

impl<'command> Command<'command> {
  pub fn new(
    command: BulkString,
    arguments: &'command [BulkString],

    store: Arc<Mutex<Store>>
  ) -> Self {
    Self {
      command,
      arguments: arguments.iter(),

      store
    }
  }

  pub fn handle(&'command mut self) -> Result<Data, CommandExecutionError> {
    match self.command.as_str() {
      "PING" => self.ping(),

      "ECHO" => self.echo(),

      // Handling commands related to Redis Strings.
      "SET" => self.set(),
      "GET" => self.get(),

      _ => Err(CommandExecutionError::UnknownCommand)
    }
  }
}
