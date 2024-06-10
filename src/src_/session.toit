import .ble show Process_
import ..provision show Security

class SessionProcess_ implements Process_:
  security_/Security

  constructor .security_/Security:

  run data/ByteArray -> ByteArray:
    return security_.handshake data
