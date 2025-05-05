import gleeunit/should
import resp/data
import resp/parse

pub fn parse_simple_string_test() {
  <<"+PING\r\n":utf8>>
  |> parse.parse
  |> should.equal(Ok(parse.ParseOutput(data.SimpleString("PING"), <<>>)))
}

pub fn parse_bulk_string_test() {
  <<"$4\r\nPING\r\n":utf8>>
  |> parse.parse
  |> should.equal(Ok(parse.ParseOutput(data.BulkString("PING"), <<>>)))
}

pub fn parse_array_test() {
  <<"*2\r\n*2\r\n+HELLO\r\n+WORLD\r\n*2\r\n+PING\r\n+PONG\r\n":utf8>>
  |> parse.parse
  |> should.equal(
    Ok(
      parse.ParseOutput(
        data.Array([
          data.Array([data.SimpleString("HELLO"), data.SimpleString("WORLD")]),
          data.Array([data.SimpleString("PING"), data.SimpleString("PONG")]),
        ]),
        <<>>,
      ),
    ),
  )
}

pub fn parse_null_test() {
  <<"_\r\n":utf8>>
  |> parse.parse
  |> should.equal(Ok(parse.ParseOutput(data.Null, <<>>)))
}
