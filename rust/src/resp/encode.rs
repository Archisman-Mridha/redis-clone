use crate::resp::data::Data;

impl Data {
  pub fn encode(&self) -> String {
    match self {
      Self::SimpleString(string) => format!("+{string}\r\n"),

      Self::BulkString(string) => {
        format!("${}\r\n{string}\r\n", string.len())
      }

      Self::Array { elements } => {
        let encoding = format!("*{}\r\n", elements.len());

        elements.iter().fold(encoding, |accumulator, element| {
          accumulator + &Self::encode(element)
        })
      }

      Self::Null => String::from("-\r\n")
    }
  }
}
