// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import ble
import io
import protobuf

import .ble show DESCRIPTOR-UUID
import .security

/**
An RPC service (not to be confused with a BLE service) is built
  on top of BLE characteristics.

A BLE device writes a value to the characteristic, and the device sets
  the value of the characteristic to the response.
*/
abstract class RpcService:
  static UUID-BASE_ ::= 0xff
  static WRITE-TIMEOUT-MS_ ::= 10 * 1000
  static PROPERTIES_ ::= ble.CHARACTERISTIC-PROPERTY-READ | ble.CHARACTERISTIC-PROPERTY-WRITE
  static PERMISSIONS_ ::= ble.CHARACTERISTIC-PERMISSION-READ | ble.CHARACTERISTIC-PERMISSION-WRITE

  static hash-counter_ := 0

  // When a new RPC call comes in, we clear all other RPC services' return values.
  static all-rpc-services_/Set? ::= {}

  characteristic_/ble.LocalCharacteristic
  description/string
  security_/Security?
  task_/Task? := null
  hash-code/int ::= hash-counter_++

  /**
  Constructs a new RPC characteristic.

  The characteristic UUID is constructed from the service UUID by replacing
    the third byte with 0xff and the 4th with the id.
  */
  constructor
      service/ble.LocalService
      id/int
      --.description
      --security/Security?:
    security_ = security

    uuid := service.uuid.to-byte-array.copy
    uuid[2] = UUID-BASE_
    uuid[3] = id

    characteristic_ = service.add-characteristic
        ble.BleUuid uuid
        --properties=PROPERTIES_
        --permissions=PERMISSIONS_
    characteristic_.add-descriptor DESCRIPTOR-UUID
        --properties=ble.CHARACTERISTIC-PROPERTY-READ
        --permissions=ble.CHARACTERISTIC-PERMISSION-READ
        --value=description

    all-rpc-services_.add this
    task_ = task:: run_

  /**
  Handles an incoming request from a client (like a phone).
  */
  abstract handle-request data/ByteArray -> ByteArray

  close -> none:
    critical-do:
      all-rpc-services_.remove this
      if task_:
        task_.cancel
        task_ = null

  run_ -> none:
    while true:
      characteristic_.handle-write-request --timeout-ms=WRITE_TIMEOUT_MS_: | data/ByteArray |
        if security_: data = security_.decrypt data
        response-bytes := handle-request data
        if security_: response-bytes = security_.encrypt response-bytes
        all-rpc-services_.do: | service/RpcService |
          if service != this:
            service.characteristic_.set-value null
        characteristic_.set-value response-bytes

/**
An RPC service that uses Protobuf for serialization.
*/
abstract class ProtobufRpcService extends RpcService:
  constructor
      service/ble.LocalService
      id/int
      --description/string
      --security/Security?:
    super service id --description=description --security=security

  handle-request data/ByteArray -> ByteArray:
    response-message := handle-proto-request data
    return protobuf-message-to-bytes_ response-message

  abstract handle-proto-request data/ByteArray -> protobuf.Message

  static protobuf-message-to-bytes_ message/protobuf.Message -> ByteArray:
    buffer := io.Buffer
    writer := protobuf.Writer buffer
    message.serialize writer
    return buffer.bytes
