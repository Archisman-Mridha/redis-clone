pub type Data {
  SimpleString(string: String)
  BulkString(binary_string: String)
  Array(elements: List(Data))
  Null
}
