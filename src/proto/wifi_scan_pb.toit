// Code generated by protoc-gen-toit. DO NOT EDIT.
// source: wifi_scan.proto

import protobuf as _protobuf
import core as _core
import .constants_pb as _constants
import .wifi_constants_pb as _wifi_constants

// ENUM START: WiFiScanMsgType
WiFiScanMsgType_TypeCmdScanStart/int/*enum<WiFiScanMsgType>*/ ::= 0
WiFiScanMsgType_TypeRespScanStart/int/*enum<WiFiScanMsgType>*/ ::= 1
WiFiScanMsgType_TypeCmdScanStatus/int/*enum<WiFiScanMsgType>*/ ::= 2
WiFiScanMsgType_TypeRespScanStatus/int/*enum<WiFiScanMsgType>*/ ::= 3
WiFiScanMsgType_TypeCmdScanResult/int/*enum<WiFiScanMsgType>*/ ::= 4
WiFiScanMsgType_TypeRespScanResult/int/*enum<WiFiScanMsgType>*/ ::= 5
// ENUM END: .WiFiScanMsgType

// MESSAGE START: .CmdScanStart
class CmdScanStart extends _protobuf.Message:
  blocking/bool := false
  passive/bool := false
  group_channels/int := 0
  period_ms/int := 0

  constructor
      --blocking/bool?=null
      --passive/bool?=null
      --group_channels/int?=null
      --period_ms/int?=null:
    if blocking != null:
      this.blocking = blocking
    if passive != null:
      this.passive = passive
    if group_channels != null:
      this.group_channels = group_channels
    if period_ms != null:
      this.period_ms = period_ms

  constructor.deserialize r/_protobuf.Reader:
    r.read_message:
      r.read_field 1:
        blocking = r.read_primitive _protobuf.PROTOBUF_TYPE_BOOL
      r.read_field 2:
        passive = r.read_primitive _protobuf.PROTOBUF_TYPE_BOOL
      r.read_field 3:
        group_channels = r.read_primitive _protobuf.PROTOBUF_TYPE_UINT32
      r.read_field 4:
        period_ms = r.read_primitive _protobuf.PROTOBUF_TYPE_UINT32

  serialize w/_protobuf.Writer --as_field/int?=null --oneof/bool=false -> none:
    w.write_message_header this --as_field=as_field --oneof=oneof
    w.write_primitive _protobuf.PROTOBUF_TYPE_BOOL blocking --as_field=1
    w.write_primitive _protobuf.PROTOBUF_TYPE_BOOL passive --as_field=2
    w.write_primitive _protobuf.PROTOBUF_TYPE_UINT32 group_channels --as_field=3
    w.write_primitive _protobuf.PROTOBUF_TYPE_UINT32 period_ms --as_field=4

  num_fields_set -> int:
    return (blocking == false ? 0 : 1)
      + (passive == false ? 0 : 1)
      + (group_channels == 0 ? 0 : 1)
      + (period_ms == 0 ? 0 : 1)

  protobuf_size -> int:
    return (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_BOOL blocking --as_field=1)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_BOOL passive --as_field=2)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_UINT32 group_channels --as_field=3)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_UINT32 period_ms --as_field=4)

// MESSAGE END: .CmdScanStart

// MESSAGE START: .RespScanStart
class RespScanStart extends _protobuf.Message:

  constructor:

  constructor.deserialize r/_protobuf.Reader:
    r.read_message:
      1

  serialize w/_protobuf.Writer --as_field/int?=null --oneof/bool=false -> none:
    w.write_message_header this --as_field=as_field --oneof=oneof
    1
  num_fields_set -> int:
    return 0

  protobuf_size -> int:
    return 0

// MESSAGE END: .RespScanStart

// MESSAGE START: .CmdScanStatus
class CmdScanStatus extends _protobuf.Message:

  constructor:

  constructor.deserialize r/_protobuf.Reader:
    r.read_message:
      1

  serialize w/_protobuf.Writer --as_field/int?=null --oneof/bool=false -> none:
    w.write_message_header this --as_field=as_field --oneof=oneof
    1
  num_fields_set -> int:
    return 0

  protobuf_size -> int:
    return 0

// MESSAGE END: .CmdScanStatus

// MESSAGE START: .RespScanStatus
class RespScanStatus extends _protobuf.Message:
  scan_finished/bool := false
  result_count/int := 0

  constructor
      --scan_finished/bool?=null
      --result_count/int?=null:
    if scan_finished != null:
      this.scan_finished = scan_finished
    if result_count != null:
      this.result_count = result_count

  constructor.deserialize r/_protobuf.Reader:
    r.read_message:
      r.read_field 1:
        scan_finished = r.read_primitive _protobuf.PROTOBUF_TYPE_BOOL
      r.read_field 2:
        result_count = r.read_primitive _protobuf.PROTOBUF_TYPE_UINT32

  serialize w/_protobuf.Writer --as_field/int?=null --oneof/bool=false -> none:
    w.write_message_header this --as_field=as_field --oneof=oneof
    w.write_primitive _protobuf.PROTOBUF_TYPE_BOOL scan_finished --as_field=1
    w.write_primitive _protobuf.PROTOBUF_TYPE_UINT32 result_count --as_field=2

  num_fields_set -> int:
    return (scan_finished == false ? 0 : 1)
      + (result_count == 0 ? 0 : 1)

  protobuf_size -> int:
    return (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_BOOL scan_finished --as_field=1)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_UINT32 result_count --as_field=2)

// MESSAGE END: .RespScanStatus

// MESSAGE START: .CmdScanResult
class CmdScanResult extends _protobuf.Message:
  start_index/int := 0
  count/int := 0

  constructor
      --start_index/int?=null
      --count/int?=null:
    if start_index != null:
      this.start_index = start_index
    if count != null:
      this.count = count

  constructor.deserialize r/_protobuf.Reader:
    r.read_message:
      r.read_field 1:
        start_index = r.read_primitive _protobuf.PROTOBUF_TYPE_UINT32
      r.read_field 2:
        count = r.read_primitive _protobuf.PROTOBUF_TYPE_UINT32

  serialize w/_protobuf.Writer --as_field/int?=null --oneof/bool=false -> none:
    w.write_message_header this --as_field=as_field --oneof=oneof
    w.write_primitive _protobuf.PROTOBUF_TYPE_UINT32 start_index --as_field=1
    w.write_primitive _protobuf.PROTOBUF_TYPE_UINT32 count --as_field=2

  num_fields_set -> int:
    return (start_index == 0 ? 0 : 1)
      + (count == 0 ? 0 : 1)

  protobuf_size -> int:
    return (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_UINT32 start_index --as_field=1)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_UINT32 count --as_field=2)

// MESSAGE END: .CmdScanResult

// MESSAGE START: .WiFiScanResult
class WiFiScanResult extends _protobuf.Message:
  ssid/ByteArray := ByteArray 0
  channel/int := 0
  rssi/int := 0
  bssid/ByteArray := ByteArray 0
  auth/int/*enum<_wifi_constants.WifiAuthMode>*/ := 0

  constructor
      --ssid/ByteArray?=null
      --channel/int?=null
      --rssi/int?=null
      --bssid/ByteArray?=null
      --auth/int?/*enum<_wifi_constants.WifiAuthMode>?*/=null:
    if ssid != null:
      this.ssid = ssid
    if channel != null:
      this.channel = channel
    if rssi != null:
      this.rssi = rssi
    if bssid != null:
      this.bssid = bssid
    if auth != null:
      this.auth = auth

  constructor.deserialize r/_protobuf.Reader:
    r.read_message:
      r.read_field 1:
        ssid = r.read_primitive _protobuf.PROTOBUF_TYPE_BYTES
      r.read_field 2:
        channel = r.read_primitive _protobuf.PROTOBUF_TYPE_UINT32
      r.read_field 3:
        rssi = r.read_primitive _protobuf.PROTOBUF_TYPE_INT32
      r.read_field 4:
        bssid = r.read_primitive _protobuf.PROTOBUF_TYPE_BYTES
      r.read_field 5:
        auth = r.read_primitive _protobuf.PROTOBUF_TYPE_ENUM

  serialize w/_protobuf.Writer --as_field/int?=null --oneof/bool=false -> none:
    w.write_message_header this --as_field=as_field --oneof=oneof
    w.write_primitive _protobuf.PROTOBUF_TYPE_BYTES ssid --as_field=1
    w.write_primitive _protobuf.PROTOBUF_TYPE_UINT32 channel --as_field=2
    w.write_primitive _protobuf.PROTOBUF_TYPE_INT32 rssi --as_field=3
    w.write_primitive _protobuf.PROTOBUF_TYPE_BYTES bssid --as_field=4
    w.write_primitive _protobuf.PROTOBUF_TYPE_ENUM auth --as_field=5

  num_fields_set -> int:
    return (ssid.is_empty ? 0 : 1)
      + (channel == 0 ? 0 : 1)
      + (rssi == 0 ? 0 : 1)
      + (bssid.is_empty ? 0 : 1)
      + (auth == 0 ? 0 : 1)

  protobuf_size -> int:
    return (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_BYTES ssid --as_field=1)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_UINT32 channel --as_field=2)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_INT32 rssi --as_field=3)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_BYTES bssid --as_field=4)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_ENUM auth --as_field=5)

// MESSAGE END: .WiFiScanResult

// MESSAGE START: .RespScanResult
class RespScanResult extends _protobuf.Message:
  entries/List/*<WiFiScanResult>*/ := []

  constructor
      --entries/List?/*<WiFiScanResult>*/=null:
    if entries != null:
      this.entries = entries

  constructor.deserialize r/_protobuf.Reader:
    r.read_message:
      r.read_field 1:
        entries = r.read_array _protobuf.PROTOBUF_TYPE_MESSAGE entries:
          WiFiScanResult.deserialize r

  serialize w/_protobuf.Writer --as_field/int?=null --oneof/bool=false -> none:
    w.write_message_header this --as_field=as_field --oneof=oneof
    w.write_array _protobuf.PROTOBUF_TYPE_MESSAGE entries --as_field=1: | value/WiFiScanResult | 
      value.serialize w

  num_fields_set -> int:
    return (entries.is_empty ? 0 : 1)

  protobuf_size -> int:
    return (_protobuf.size_array _protobuf.PROTOBUF_TYPE_MESSAGE entries --as_field=1)

// MESSAGE END: .RespScanResult

// MESSAGE START: .WiFiScanPayload
class WiFiScanPayload extends _protobuf.Message:
  // ONEOF START: .WiFiScanPayload.payload
  payload_ := null
  payload_oneof_case_/int? := null

  payload_oneof_clear -> none:
    payload_ = null
    payload_oneof_case_ = null

  static PAYLOAD_CMD_SCAN_START/int ::= 10
  static PAYLOAD_RESP_SCAN_START/int ::= 11
  static PAYLOAD_CMD_SCAN_STATUS/int ::= 12
  static PAYLOAD_RESP_SCAN_STATUS/int ::= 13
  static PAYLOAD_CMD_SCAN_RESULT/int ::= 14
  static PAYLOAD_RESP_SCAN_RESULT/int ::= 15

  payload_oneof_case -> int?:
    return payload_oneof_case_

  payload_cmd_scan_start -> CmdScanStart:
    return payload_

  payload_cmd_scan_start= payload/CmdScanStart -> none:
    payload_ = payload
    payload_oneof_case_ = PAYLOAD_CMD_SCAN_START

  payload_resp_scan_start -> RespScanStart:
    return payload_

  payload_resp_scan_start= payload/RespScanStart -> none:
    payload_ = payload
    payload_oneof_case_ = PAYLOAD_RESP_SCAN_START

  payload_cmd_scan_status -> CmdScanStatus:
    return payload_

  payload_cmd_scan_status= payload/CmdScanStatus -> none:
    payload_ = payload
    payload_oneof_case_ = PAYLOAD_CMD_SCAN_STATUS

  payload_resp_scan_status -> RespScanStatus:
    return payload_

  payload_resp_scan_status= payload/RespScanStatus -> none:
    payload_ = payload
    payload_oneof_case_ = PAYLOAD_RESP_SCAN_STATUS

  payload_cmd_scan_result -> CmdScanResult:
    return payload_

  payload_cmd_scan_result= payload/CmdScanResult -> none:
    payload_ = payload
    payload_oneof_case_ = PAYLOAD_CMD_SCAN_RESULT

  payload_resp_scan_result -> RespScanResult:
    return payload_

  payload_resp_scan_result= payload/RespScanResult -> none:
    payload_ = payload
    payload_oneof_case_ = PAYLOAD_RESP_SCAN_RESULT

  // ONEOF END: .WiFiScanPayload.payload
  msg/int/*enum<WiFiScanMsgType>*/ := 0
  status/int/*enum<_constants.Status>*/ := 0

  constructor
      --msg/int?/*enum<WiFiScanMsgType>?*/=null
      --status/int?/*enum<_constants.Status>?*/=null
      --payload_cmd_scan_start/CmdScanStart?=null
      --payload_resp_scan_start/RespScanStart?=null
      --payload_cmd_scan_status/CmdScanStatus?=null
      --payload_resp_scan_status/RespScanStatus?=null
      --payload_cmd_scan_result/CmdScanResult?=null
      --payload_resp_scan_result/RespScanResult?=null:
    if msg != null:
      this.msg = msg
    if status != null:
      this.status = status
    if payload_cmd_scan_start != null:
      this.payload_cmd_scan_start = payload_cmd_scan_start
    if payload_resp_scan_start != null:
      this.payload_resp_scan_start = payload_resp_scan_start
    if payload_cmd_scan_status != null:
      this.payload_cmd_scan_status = payload_cmd_scan_status
    if payload_resp_scan_status != null:
      this.payload_resp_scan_status = payload_resp_scan_status
    if payload_cmd_scan_result != null:
      this.payload_cmd_scan_result = payload_cmd_scan_result
    if payload_resp_scan_result != null:
      this.payload_resp_scan_result = payload_resp_scan_result

  constructor.deserialize r/_protobuf.Reader:
    r.read_message:
      r.read_field 1:
        msg = r.read_primitive _protobuf.PROTOBUF_TYPE_ENUM
      r.read_field 2:
        status = r.read_primitive _protobuf.PROTOBUF_TYPE_ENUM
      r.read_field 10:
        payload_cmd_scan_start = CmdScanStart.deserialize r
      r.read_field 11:
        payload_resp_scan_start = RespScanStart.deserialize r
      r.read_field 12:
        payload_cmd_scan_status = CmdScanStatus.deserialize r
      r.read_field 13:
        payload_resp_scan_status = RespScanStatus.deserialize r
      r.read_field 14:
        payload_cmd_scan_result = CmdScanResult.deserialize r
      r.read_field 15:
        payload_resp_scan_result = RespScanResult.deserialize r

  serialize w/_protobuf.Writer --as_field/int?=null --oneof/bool=false -> none:
    w.write_message_header this --as_field=as_field --oneof=oneof
    w.write_primitive _protobuf.PROTOBUF_TYPE_ENUM msg --as_field=1
    w.write_primitive _protobuf.PROTOBUF_TYPE_ENUM status --as_field=2
    if payload_oneof_case_ == PAYLOAD_CMD_SCAN_START:
      payload_.serialize w --as_field=PAYLOAD_CMD_SCAN_START --oneof
    if payload_oneof_case_ == PAYLOAD_RESP_SCAN_START:
      payload_.serialize w --as_field=PAYLOAD_RESP_SCAN_START --oneof
    if payload_oneof_case_ == PAYLOAD_CMD_SCAN_STATUS:
      payload_.serialize w --as_field=PAYLOAD_CMD_SCAN_STATUS --oneof
    if payload_oneof_case_ == PAYLOAD_RESP_SCAN_STATUS:
      payload_.serialize w --as_field=PAYLOAD_RESP_SCAN_STATUS --oneof
    if payload_oneof_case_ == PAYLOAD_CMD_SCAN_RESULT:
      payload_.serialize w --as_field=PAYLOAD_CMD_SCAN_RESULT --oneof
    if payload_oneof_case_ == PAYLOAD_RESP_SCAN_RESULT:
      payload_.serialize w --as_field=PAYLOAD_RESP_SCAN_RESULT --oneof

  num_fields_set -> int:
    return (payload_oneof_case_ == null ? 0 : 1)
      + (msg == 0 ? 0 : 1)
      + (status == 0 ? 0 : 1)

  protobuf_size -> int:
    return (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_ENUM msg --as_field=1)
      + (_protobuf.size_primitive _protobuf.PROTOBUF_TYPE_ENUM status --as_field=2)
      + (payload_oneof_case_ == PAYLOAD_CMD_SCAN_START ? (_protobuf.size_embedded_message (payload_cmd_scan_start.protobuf_size) --as_field=10) : 0)
      + (payload_oneof_case_ == PAYLOAD_RESP_SCAN_START ? (_protobuf.size_embedded_message (payload_resp_scan_start.protobuf_size) --as_field=11) : 0)
      + (payload_oneof_case_ == PAYLOAD_CMD_SCAN_STATUS ? (_protobuf.size_embedded_message (payload_cmd_scan_status.protobuf_size) --as_field=12) : 0)
      + (payload_oneof_case_ == PAYLOAD_RESP_SCAN_STATUS ? (_protobuf.size_embedded_message (payload_resp_scan_status.protobuf_size) --as_field=13) : 0)
      + (payload_oneof_case_ == PAYLOAD_CMD_SCAN_RESULT ? (_protobuf.size_embedded_message (payload_cmd_scan_result.protobuf_size) --as_field=14) : 0)
      + (payload_oneof_case_ == PAYLOAD_RESP_SCAN_RESULT ? (_protobuf.size_embedded_message (payload_resp_scan_result.protobuf_size) --as_field=15) : 0)

// MESSAGE END: .WiFiScanPayload

