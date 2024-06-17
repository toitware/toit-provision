// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import ble
import protobuf

import .rpc
import .security show Security

/**
An RPC service responsible for establishing a session between the client and the server.

Depending on the used $security_ object, the session can be encrypted or not.
*/
class SessionRpcService extends ProtobufRpcService:
  static ID_ ::= 0x51
  static DESCRIPTION_ ::= "prov-session"

  session-security_/Security

  constructor service/ble.LocalService --security/Security:
    // Despite having the security object, we don't communicate in an encrypted way.
    // This service is responsible for establishing the secure connection, so we
    // can't use it to communicate.
    session-security_ = security
    super service ID_ --description=DESCRIPTION_ --security=null

  handle-proto-request data/ByteArray -> protobuf.Message:
    return session-security_.handle-handshake-request data
