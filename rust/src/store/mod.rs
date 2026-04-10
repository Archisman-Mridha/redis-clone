use std::{collections::HashMap, time::SystemTime};

pub type Store = HashMap<String, Value>;

pub enum Value {
  /// Redis strings store sequences of bytes, including text, serialized objects, and binary
  /// arrays. As such, strings are the simplest type of value you can associate with a Redis key.
  ///
  /// Values can be strings (including binary data) of every kind, for instance you can store a
  /// jpeg image inside a value. A value can't be bigger than 512 MB.
  String {
    value:      String,
    expires_at: Option<SystemTime>
  },

  /// A Redis sorted set is a collection of unique strings (members) ordered by an associated
  /// score. When more than one string has the same score, the strings are ordered
  /// lexicographically.
  ///
  /// Sorted sets are implemented via a dual-ported data structure containing both a skip list and
  /// a hash table, so every time we add an element Redis performs an O(log(N)) operation. That's
  /// good, so when we ask for sorted elements, Redis does not have to do any work at all, it's
  /// already sorted.
  SortedSet
}
