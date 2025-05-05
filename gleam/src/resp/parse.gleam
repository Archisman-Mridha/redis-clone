import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result
import resp/data

pub type ParseOutput {
  ParseOutput(data: data.Data, remaining_input: BitArray)
}

pub type ParseError {
  InvalidUTF8Character
  FailedParsingLength
  UnexpectedInput
  UnexpectedEndOfInput
}

pub fn parse(bits: BitArray) -> Result(ParseOutput, ParseError) {
  // The first byte in an RESP-serialized payload always identifies its type.
  // Subsequent bytes constitute the type's contents.
  case bits {
    <<"+":utf8, remaining_bits:bits>> -> parse_simple_string(remaining_bits)
    <<"$":utf8, remaining_bits:bits>> -> parse_bulk_string(remaining_bits)
    <<"*":utf8, remaining_bits:bits>> -> parse_array(remaining_bits)
    <<"_":utf8, remaining_bits:bits>> -> parse_null(remaining_bits)

    _ -> Error(UnexpectedInput)
  }
}

// Simple strings are encoded as a plus (+) character, followed by a string. The string mustn't
// contain a CR (\r) or LF (\n) character and is terminated by CRLF(\r\n).
//
// For example, many Redis commands reply with just "OK" on success. The encoding of this Simple
// String is the following 5 bytes :
//
//  +OK\r\n
fn parse_simple_string(input: BitArray) -> Result(ParseOutput, ParseError) {
  use #(string_as_bits, remaining_input) <- result.try(
    consume_till_crlf(input, <<>>),
  )

  use string <- result.try(
    bit_array.to_string(string_as_bits)
    |> result.map_error(fn(_) { InvalidUTF8Character }),
  )

  Ok(ParseOutput(data.SimpleString(string), remaining_input))
}

// A bulk string represents a single binary string.
// RESP encodes bulk strings in the following way :
//
//    $<length>\r\n<data>\r\n
fn parse_bulk_string(input: BitArray) -> Result(ParseOutput, ParseError) {
  use #(binary_string_length, remaining_input) <- result.try(parse_length(input))

  use #(binary_string_as_bits, remaining_input) <- result.try(
    consume(remaining_input, binary_string_length, <<>>),
  )

  use binary_string <- result.try(
    bit_array.to_string(binary_string_as_bits)
    |> result.map_error(fn(_) { InvalidUTF8Character }),
  )

  case remaining_input {
    <<"\r\n":utf8, remaining_input:bits>> ->
      Ok(ParseOutput(data.BulkString(binary_string), remaining_input))

    <<>> -> Error(UnexpectedEndOfInput)

    _ -> Error(UnexpectedInput)
  }
}

// RESP Arrays' encoding uses the following format:
//
//  *<number-of-elements>\r\n<element-1>...<element-n>
//
// All of the aggregate RESP types support nesting.
fn parse_array(input: BitArray) -> Result(ParseOutput, ParseError) {
  use #(array_length, remaining_input) <- result.try(parse_length(input))

  use #(elements, remaining_input) <- result.try(
    parse_array_elements(remaining_input, array_length, []),
  )

  Ok(ParseOutput(data.Array(elements), remaining_input))
}

fn parse_array_elements(
  input: BitArray,
  array_size: Int,
  elements: List(data.Data),
) -> Result(#(List(data.Data), BitArray), ParseError) {
  case array_size {
    0 -> Ok(#(elements, input))

    _ -> {
      use ParseOutput(element, remaining_input) <- result.try(parse(input))
      let elements = list.append(elements, [element])

      parse_array_elements(remaining_input, array_size - 1, elements)
    }
  }
}

// The null data type represents non-existent values.
// Nulls' encoding is the underscore (_) character, followed by the CRLF terminator (\r\n). Here's
// Null's raw RESP encoding:
//
//  _\r\n
fn parse_null(input: BitArray) -> Result(ParseOutput, ParseError) {
  case input {
    <<"\r\n":utf8, remaining_input:bits>> ->
      Ok(ParseOutput(data.Null, remaining_input))

    <<>> -> Error(UnexpectedEndOfInput)

    _ -> Error(UnexpectedInput)
  }
}

fn parse_length(input: BitArray) -> Result(#(Int, BitArray), ParseError) {
  use #(length_as_bits, remaining_input) <- result.try(
    consume_till_crlf(input, <<>>),
  )

  use length_as_string <- result.try(
    bit_array.to_string(length_as_bits)
    |> result.map_error(fn(_) { InvalidUTF8Character }),
  )

  use length <- result.try(
    int.parse(length_as_string)
    |> result.map_error(fn(_) { FailedParsingLength }),
  )

  Ok(#(length, remaining_input))
}

fn consume_till_crlf(
  input: BitArray,
  consumed: BitArray,
) -> Result(#(BitArray, BitArray), ParseError) {
  case input {
    <<"\r\n":utf8, remaining_input:bits>> -> Ok(#(consumed, remaining_input))

    <<character, remaining_input:bits>> ->
      consume_till_crlf(remaining_input, <<consumed:bits, character>>)

    _ -> Error(UnexpectedEndOfInput)
  }
}

fn consume(
  input: BitArray,
  consumption_size: Int,
  consumed: BitArray,
) -> Result(#(BitArray, BitArray), ParseError) {
  case consumption_size {
    0 -> Ok(#(consumed, input))

    _ ->
      case input {
        <<character, remaining_input:bits>> ->
          consume(remaining_input, consumption_size - 1, <<
            consumed:bits,
            character,
          >>)

        _ -> Error(UnexpectedEndOfInput)
      }
  }
}
