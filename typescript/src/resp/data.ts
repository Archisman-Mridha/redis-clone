import { Data } from "effect"

export type TData = Data.TaggedEnum<{
  /*
    Simple strings are encoded as a plus (+) character, followed by a string. The string mustn't
    contain a CR (\r) or LF (\n) character and is terminated by CRLF(\r\n).

    For example, many Redis commands reply with just "OK" on success. The encoding of this Simple
    String is the following 5 bytes :

      +OK\r\n
  */
  SimpleString: { string: string }

  /*
    A bulk string represents a single binary string.
    RESP encodes bulk strings in the following way :

      $<length>\r\n<data>\r\n
  */
  BulkString: { string: string }

  /*
    RESP Arrays' encoding uses the following format:

      *<number-of-elements>\r\n<element-1>...<element-n>

    All of the aggregate RESP types support nesting.
  */
  Array: { elements: TData }

  /*
    The null data type represents non-existent values.
    Nulls' encoding is the underscore (_) character, followed by the CRLF terminator (\r\n).
    Here's Null's raw RESP encoding:

      _\r\n
  */
  Null: {}
}>

export type TSimpleString = Data.TaggedEnum.Value<TData, "SimpleString">
export type TBulkString = Data.TaggedEnum.Value<TData, "BulkString">
export type TArray = Data.TaggedEnum.Value<TData, "Array">
export type TNull = Data.TaggedEnum.Value<TData, "Null">

export const { SimpleString, BulkString, Array, Null } = Data.taggedEnum<TData>()
