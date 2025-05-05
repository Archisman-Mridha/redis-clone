// To communicate with the Redis server, Redis clients use a protocol called Redis Serialization
// Protocol (RESP).
//
// Clients send commands to a Redis server as an array of bulk strings. The first (and sometimes
// also the second) bulk string in the array is the command's name. Subsequent elements of the
// array are the arguments for the command.
