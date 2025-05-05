import gleam/int
import gleam/list
import gleam/string
import resp/data

// Returns a buffer containing encoding of the given RESP data.
pub fn encode(data: data.Data) -> BitArray {
  encode_into_buffer(<<>>, data)
}

fn encode_into_buffer(buffer: BitArray, data: data.Data) -> BitArray {
  let encoding = case data {
    data.SimpleString(string) -> <<string.concat(["+", string, "\r\n"]):utf8>>

    data.BulkString(binary_string) -> <<
      string.concat([
        "$",
        int.to_string(string.length(binary_string)),
        "\r\n",
        binary_string,
        "\r\n",
      ]):utf8,
    >>

    data.Array(elements) -> {
      let encoding_buffer = <<
        string.concat(["*", int.to_string(list.length(elements)), "\r\n"]):utf8,
      >>

      list.fold(elements, encoding_buffer, encode_into_buffer)
    }

    data.Null -> <<"_\r\n":utf8>>
  }

  let buffer = <<buffer:bits, encoding:bits>>
  buffer
}
