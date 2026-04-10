use {
  crate::{error::ParseError, resp::data::Data},
  std::io
};

pub struct Parser<R>
where
  R: Iterator<Item = io::Result<u8>>
{
  request: R
}

impl<R> Parser<R>
where
  R: Iterator<Item = io::Result<u8>>
{
  pub fn new(request: R) -> Self {
    Self { request }
  }

  pub fn parse(&mut self) -> Result<Data, ParseError> {
    let character = self
      .request
      .next()
      .ok_or(ParseError::UnexpectedInput)
      .and_then(|bit| match bit {
        Ok(bit) => Ok(bit),

        Err(error) => {
          eprintln!("unexpected error when trying to read from byte iterator in Parser : {error}");
          Err(ParseError::UnexpectedError)
        }
      })
      .and_then(|bit| match bit.as_ascii() {
        Some(character) => Ok(character),

        None => Err(ParseError::InvalidUTF8Character)
      })?;

    match character.as_str() {
      "+" => self.parse_simple_string(),
      "$" => self.parse_bulk_string(),
      "*" => self.parse_array(),
      "_" => self.parse_null(),

      _ => Err(ParseError::UnexpectedInput)
    }
  }

  fn parse_simple_string(&mut self) -> Result<Data, ParseError> {
    self.consume_till_crlf().map(Data::SimpleString)
  }

  fn parse_bulk_string(&mut self) -> Result<Data, ParseError> {
    let length = self
      .consume_till_crlf()?
      .parse::<usize>()
      .map_err(|_| ParseError::FailedParsingLength)?;

    let mut bytes = Vec::with_capacity(length);

    for _ in 0..length {
      match self.request.next() {
        Some(Ok(byte)) => bytes.push(byte),
        Some(Err(_)) => return Err(ParseError::UnexpectedError),
        None => return Err(ParseError::UnexpectedEndOfInput)
      }
    }

    match (self.request.next(), self.request.next()) {
      (Some(Ok(b'\r')), Some(Ok(b'\n'))) => {}
      _ => return Err(ParseError::UnexpectedInput)
    }

    String::from_utf8(bytes)
      .map(Data::BulkString)
      .map_err(|_| ParseError::InvalidUTF8Character)
  }

  fn parse_array(&mut self) -> Result<Data, ParseError> {
    let count = self
      .consume_till_crlf()?
      .parse::<usize>()
      .map_err(|_| ParseError::FailedParsingLength)?;

    let mut elements = Vec::with_capacity(count);

    for _ in 0..count {
      elements.push(self.parse()?);
    }

    Ok(Data::Array { elements })
  }

  fn parse_null(&mut self) -> Result<Data, ParseError> {
    match (self.request.next(), self.request.next()) {
      (Some(Ok(b'\r')), Some(Ok(b'\n'))) => Ok(Data::Null),
      _ => Err(ParseError::UnexpectedInput)
    }
  }

  fn consume_till_crlf(&mut self) -> Result<String, ParseError> {
    let mut bytes = Vec::new();

    loop {
      match self.request.next() {
        Some(Ok(b'\r')) => match self.request.next() {
          Some(Ok(b'\n')) => break,
          _ => return Err(ParseError::UnexpectedInput)
        },

        Some(Ok(byte)) => bytes.push(byte),
        Some(Err(_)) => return Err(ParseError::UnexpectedError),
        None => return Err(ParseError::UnexpectedEndOfInput)
      }
    }

    String::from_utf8(bytes).map_err(|_| ParseError::InvalidUTF8Character)
  }
}
