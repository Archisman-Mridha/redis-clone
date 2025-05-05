import gleeunit/should
import resp/data
import resp/encode

pub fn encode_simple_string_test() {
  data.SimpleString("PING")
  |> encode.encode
  |> should.equal(<<"+PING\r\n":utf8>>)
}

pub fn encode_bulk_string_test() {
  data.BulkString("PING")
  |> encode.encode
  |> should.equal(<<"$4\r\nPING\r\n":utf8>>)
}

pub fn encode_array_test() {
  data.Array([
    data.Array([data.SimpleString("HELLO"), data.SimpleString("WORLD")]),
    data.Array([data.SimpleString("PING"), data.SimpleString("PONG")]),
  ])
  |> encode.encode
  |> should.equal(<<
    "*2\r\n*2\r\n+HELLO\r\n+WORLD\r\n*2\r\n+PING\r\n+PONG\r\n":utf8,
  >>)
}

pub fn encode_null_test() {
  data.Null
  |> encode.encode
  |> should.equal(<<"_\r\n":utf8>>)
}
