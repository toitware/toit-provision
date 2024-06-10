import io
import protobuf

protobuf-message-to-bytes_ message/protobuf.Message -> ByteArray:
  buffer := io.Buffer
  w := protobuf.Writer buffer
  message.serialize w
  return buffer.bytes
