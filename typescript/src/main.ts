function main( ) {
  console.log("💫 Running Redis TCP server....")

  // TODO : Move to a multi-threaded TCP server.
  Bun.listen({
    hostname: "127.0.0.1",
    port: 6379,

    // For performance-sensitive servers, assigning listeners to each socket can cause significant
    // garbage collector pressure and increase memory usage. By contrast, Bun only allocates one
    // handler function for each event and shares it among all sockets. This is a small
    // optimization, but it adds up.
    socket: {
      // On  message received from client.
      data: (socket, data) => handleRequest(socket, data)
    }
  })
}

main( )

function handleRequest(socket: Bun.Socket, data: Buffer<ArrayBufferLike>) {}
