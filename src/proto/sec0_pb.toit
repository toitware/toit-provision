// Code generated by protoc-gen-toit. DO NOT EDIT.
// source: sec0.proto

import protobuf as _protobuf
import core as _core
import .constants-pb as _constants

// ENUM START: Sec0MsgType
Sec0MsgType-S0-Session-Command/int/*enum<Sec0MsgType>*/ ::= 0
Sec0MsgType-S0-Session-Response/int/*enum<Sec0MsgType>*/ ::= 1
// ENUM END: .Sec0MsgType

// MESSAGE START: .S0SessionCmd
class S0SessionCmd extends _protobuf.Message:

  constructor:

  constructor.deserialize r/_protobuf.Reader:
    r.read-message:
      1

  serialize w/_protobuf.Writer --as-field/int?=null --oneof/bool=false -> none:
    w.write-message-header this --as-field=as-field --oneof=oneof
    1
  num-fields-set -> int:
    return 0

  protobuf-size -> int:
    return 0

// MESSAGE END: .S0SessionCmd

// MESSAGE START: .S0SessionResp
class S0SessionResp extends _protobuf.Message:
  status/int/*enum<_constants.Status>*/ := 0

  constructor
      --status/int?/*enum<_constants.Status>?*/=null:
    if status != null:
      this.status = status

  constructor.deserialize r/_protobuf.Reader:
    r.read-message:
      r.read-field 1:
        status = r.read-primitive _protobuf.PROTOBUF-TYPE-ENUM

  serialize w/_protobuf.Writer --as-field/int?=null --oneof/bool=false -> none:
    w.write-message-header this --as-field=as-field --oneof=oneof
    w.write-primitive _protobuf.PROTOBUF-TYPE-ENUM status --as-field=1

  num-fields-set -> int:
    return (status == 0 ? 0 : 1)

  protobuf-size -> int:
    return (_protobuf.size-primitive _protobuf.PROTOBUF-TYPE-ENUM status --as-field=1)

// MESSAGE END: .S0SessionResp

// MESSAGE START: .Sec0Payload
class Sec0Payload extends _protobuf.Message:
  // ONEOF START: .Sec0Payload.payload
  payload_ := null
  payload-oneof-case_/int? := null

  payload-oneof-clear -> none:
    payload_ = null
    payload-oneof-case_ = null

  static PAYLOAD-SC/int ::= 20
  static PAYLOAD-SR/int ::= 21

  payload-oneof-case -> int?:
    return payload-oneof-case_

  payload-sc -> S0SessionCmd:
    return payload_

  payload-sc= payload/S0SessionCmd -> none:
    payload_ = payload
    payload-oneof-case_ = PAYLOAD-SC

  payload-sr -> S0SessionResp:
    return payload_

  payload-sr= payload/S0SessionResp -> none:
    payload_ = payload
    payload-oneof-case_ = PAYLOAD-SR

  // ONEOF END: .Sec0Payload.payload
  msg/int/*enum<Sec0MsgType>*/ := 0

  constructor
      --msg/int?/*enum<Sec0MsgType>?*/=null
      --payload-sc/S0SessionCmd?=null
      --payload-sr/S0SessionResp?=null:
    if msg != null:
      this.msg = msg
    if payload-sc != null:
      this.payload-sc = payload-sc
    if payload-sr != null:
      this.payload-sr = payload-sr

  constructor.deserialize r/_protobuf.Reader:
    r.read-message:
      r.read-field 1:
        msg = r.read-primitive _protobuf.PROTOBUF-TYPE-ENUM
      r.read-field 20:
        payload-sc = S0SessionCmd.deserialize r
      r.read-field 21:
        payload-sr = S0SessionResp.deserialize r

  serialize w/_protobuf.Writer --as-field/int?=null --oneof/bool=false -> none:
    w.write-message-header this --as-field=as-field --oneof=oneof
    w.write-primitive _protobuf.PROTOBUF-TYPE-ENUM msg --as-field=1
    if payload-oneof-case_ == PAYLOAD-SC:
      payload_.serialize w --as-field=PAYLOAD-SC --oneof
    if payload-oneof-case_ == PAYLOAD-SR:
      payload_.serialize w --as-field=PAYLOAD-SR --oneof

  num-fields-set -> int:
    return (payload-oneof-case_ == null ? 0 : 1)
      + (msg == 0 ? 0 : 1)

  protobuf-size -> int:
    return (_protobuf.size-primitive _protobuf.PROTOBUF-TYPE-ENUM msg --as-field=1)
      + (payload-oneof-case_ == PAYLOAD-SC ? (_protobuf.size-embedded-message (payload-sc.protobuf-size) --as-field=20) : 0)
      + (payload-oneof-case_ == PAYLOAD-SR ? (_protobuf.size-embedded-message (payload-sr.protobuf-size) --as-field=21) : 0)

// MESSAGE END: .Sec0Payload

