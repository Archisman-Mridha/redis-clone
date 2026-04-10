#![feature(ascii_char)]

mod command;
mod error;
mod resp;
mod store;

use {
  crate::{
    command::Command,
    error::RedisError,
    resp::{data::Data, parse::Parser},
    store::Store
  },
  std::{
    collections::HashMap,
    io::{BufReader, BufWriter, Bytes, Read, Write},
    net::{TcpListener, TcpStream},
    sync::{Arc, Mutex}
  }
};

// I know that Redis is single threaded, and uses an event loop to handle requests.
// But for the sake of simplicity, Arc<Mutext<Store>> it is for now :).
#[tokio::main(flavor = "multi_thread")]
async fn main() -> Result<(), std::io::Error> {
  let listener = TcpListener::bind("127.0.0.1:6379")?;

  println!("💫 Running Redis TCP server....");

  let store = Arc::new(Mutex::new(HashMap::new() as Store));

  for connection in listener.incoming() {
    match connection {
      Ok(connection) => {
        let store = Arc::clone(&store);

        tokio::spawn(async move {
          handle_connection(connection, store);
        });
      }

      Err(error) => eprintln!("Error establishing TCP connection : {error}")
    }
  }

  Ok(())
}

fn handle_connection(connection: TcpStream, store: Arc<Mutex<Store>>) {
  let mut reader = BufReader::new(&connection).bytes();
  let mut writer = BufWriter::new(&connection);

  loop {
    let response = match handle_request(&mut reader, store.clone()) {
      Ok(response) => response.encode(),
      Err(error) => error.encode()
    };

    if let Err(error) = writer
      .write_all(response.as_bytes())
      .and_then(|_| writer.flush())
    {
      eprintln!("Failed writing response : {error}");
    }
  }
}

fn handle_request(
  reader: &mut Bytes<BufReader<&TcpStream>>,
  store: Arc<Mutex<Store>>
) -> Result<Data, RedisError> {
  let request = Parser::new(reader)
    .parse()
    .map_err(RedisError::ParseError)?;

  let elements = match request {
    Data::Array { elements } => elements,
    _ => return Err(RedisError::InvalidRequestFormat)
  };

  let mut elements = elements.into_iter();

  let command = elements
    .next()
    .ok_or(RedisError::InvalidRequestFormat)
    .and_then(|element| match element {
      Data::BulkString(command) => Ok(command),
      _ => Err(RedisError::InvalidRequestFormat)
    })?;

  let mut arguments = Vec::new();
  for element in elements {
    match element {
      Data::BulkString(argument) => arguments.push(argument),
      _ => return Err(RedisError::InvalidRequestFormat)
    }
  }

  Command::new(command, &arguments, store)
    .handle()
    .map_err(RedisError::CommandExecutionError)
}
