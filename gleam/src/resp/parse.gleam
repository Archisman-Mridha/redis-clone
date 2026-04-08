import error
import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result
import resp/data

pub type ParseOutput {
  ParseOutput(data: data.Data, remaining_input: BitArray)
}

pub fn parse(bits: BitArray) -> Result(ParseOutput, error.ParseError) {
  // The first byte in an RESP-serialized payload always identifies its type.
  // Subsequent bytes constitute the type's contents.
  case bits {
    <<"+":utf8, remaining_bits:bits>> -> parse_simple_string(remaining_bits)
    <<"$":utf8, remaining_bits:bits>> -> parse_bulk_string(remaining_bits)
    <<"*":utf8, remaining_bits:bits>> -> parse_array(remaining_bits)
    <<"_":utf8, remaining_bits:bits>> -> parse_null(remaining_bits)

    _ -> Error(error.UnexpectedInput)
  }
}

fn parse_simple_string(input: BitArray) -> Result(ParseOutput, error.ParseError) {
  use #(string_as_bits, remaining_input) <- result.try(
    consume_till_crlf(input, <<>>),
  )

  use string <- result.try(
    bit_array.to_string(string_as_bits)
    |> result.map_error(fn(_) { error.InvalidUTF8Character }),
  )

  Ok(ParseOutput(data.SimpleString(string), remaining_input))
}

fn parse_bulk_string(input: BitArray) -> Result(ParseOutput, error.ParseError) {
  use #(binary_string_length, remaining_input) <- result.try(parse_length(input))

  use #(binary_string_as_bits, remaining_input) <- result.try(
    consume(remaining_input, binary_string_length, <<>>),
  )

  use binary_string <- result.try(
    bit_array.to_string(binary_string_as_bits)
    |> result.map_error(fn(_) { error.InvalidUTF8Character }),
  )

  case remaining_input {
    <<"\r\n":utf8, remaining_input:bits>> ->
      Ok(ParseOutput(data.BulkString(binary_string), remaining_input))

    <<>> -> Error(error.UnexpectedEndOfInput)

    _ -> Error(error.UnexpectedInput)
  }
}

fn parse_array(input: BitArray) -> Result(ParseOutput, error.ParseError) {
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
) -> Result(#(List(data.Data), BitArray), error.ParseError) {
  case array_size {
    0 -> Ok(#(elements, input))

    _ -> {
      use ParseOutput(element, remaining_input) <- result.try(parse(input))
      let elements = list.append(elements, [element])

      parse_array_elements(remaining_input, array_size - 1, elements)
    }
  }
}

fn parse_null(input: BitArray) -> Result(ParseOutput, error.ParseError) {
  case input {
    <<"\r\n":utf8, remaining_input:bits>> ->
      Ok(ParseOutput(data.Null, remaining_input))

    <<>> -> Error(error.UnexpectedEndOfInput)

    _ -> Error(error.UnexpectedInput)
  }
}

fn parse_length(input: BitArray) -> Result(#(Int, BitArray), error.ParseError) {
  use #(length_as_bits, remaining_input) <- result.try(
    consume_till_crlf(input, <<>>),
  )

  use length_as_string <- result.try(
    bit_array.to_string(length_as_bits)
    |> result.map_error(fn(_) { error.InvalidUTF8Character }),
  )

  use length <- result.try(
    int.parse(length_as_string)
    |> result.map_error(fn(_) { error.FailedParsingLength }),
  )

  Ok(#(length, remaining_input))
}

fn consume_till_crlf(
  input: BitArray,
  consumed: BitArray,
) -> Result(#(BitArray, BitArray), error.ParseError) {
  case input {
    <<"\r\n":utf8, remaining_input:bits>> -> Ok(#(consumed, remaining_input))

    <<character, remaining_input:bits>> ->
      consume_till_crlf(remaining_input, <<consumed:bits, character>>)

    _ -> Error(error.UnexpectedEndOfInput)
  }
}

fn consume(
  input: BitArray,
  consumption_size: Int,
  consumed: BitArray,
) -> Result(#(BitArray, BitArray), error.ParseError) {
  case consumption_size {
    0 -> Ok(#(consumed, input))

    _ ->
      case input {
        <<character, remaining_input:bits>> ->
          consume(remaining_input, consumption_size - 1, <<
            consumed:bits,
            character,
          >>)

        _ -> Error(error.UnexpectedEndOfInput)
      }
  }
}
