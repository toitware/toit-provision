// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import ble
import encoding.json

import .rpc

/**
An RPC service to expose the version of the protocol and the security version.
*/
class VersionRpcService extends RpcService:
  static VERSION ::= "v1.1"
  static BASE-CAPS ::= ["wifi_scan"]

  static ID_ ::= 0x53
  static DESCRIPTION_ ::= "proto-ver"

  response-bytes/ByteArray

  constructor service/ble.LocalService --security-version/int:
    caps := BASE-CAPS
    if security-version == 0:
      caps = caps.copy
      caps.add "no_sec"

    response-bytes = json.encode {
      "prov": {
        "ver": VERSION,
        "sec_ver": security-version,
        "cap": caps
      }
    }

    super service ID_
        --description=DESCRIPTION_
        --security=null

  handle-request data/ByteArray -> ByteArray:
    return response-bytes
