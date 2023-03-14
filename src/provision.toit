// Copyright (C) 2022-2023 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import bytes
import encoding.json
import monitor
import net.wifi
import ble
import protobuf
import .srp
import crypto.aes show *

/** This UUID is used in PC and Phone APP by default. */
SERVICE_UUID ::= #[0x02, 0x1a, 0x90, 0x04, 0x03, 0x82, 0x4a, 0xea,
                   0xbf, 0xf4, 0x6b, 0x3f, 0x1c, 0x5a, 0xdf, 0xb4]

/** This security mode 0 doesn't encrypt/decrypt. */
SECURITY0 := Security0_

/** This security mode 2 use SRP6a + AES-GCM*/
SECURITY2 salt verifier:
  return Security2_ salt verifier

class BLECharacteristic_:
  characteristic/ble.LocalCharacteristic
  encrypted_/bool
  desc/string
  recv_task/Task? := null
  result/ByteArray := #[]
  sem := monitor.Semaphore --count=1 --limit=1

  static UUID_BASE ::= 0xff
  static READ_TIMEOUT_MS ::= 10 * 1000
  static PROPERTIES ::= ble.CHARACTERISTIC_PROPERTY_READ | ble.CHARACTERISTIC_PROPERTY_WRITE
  static PERMISSIONS ::= ble.CHARACTERISTIC_PERMISSION_READ | ble.CHARACTERISTIC_PERMISSION_WRITE
  static DESC_UUID ::= ble.BleUuid #[0x00, 0x00, 0x29, 0x01, 0x00, 0x00, 0x10, 0x00,
                                     0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb]

  constructor service/ble.LocalService service_uuid/ByteArray id/int .desc/string .encrypted_/bool:
    uuid := service_uuid.copy
    uuid[2] = UUID_BASE
    uuid[3] = id

    characteristic = service.add_characteristic
        ble.BleUuid uuid
        --properties=PROPERTIES
        --permissions=PERMISSIONS
        --read_timeout_ms=READ_TIMEOUT_MS
    characteristic.add_descriptor
        DESC_UUID
        PROPERTIES
        PERMISSIONS
        desc.to_byte_array
  
    recv_task = task:: recv_task_run

  recv_task_run:
    characteristic.handle_read_request:
      sem.down
      sem.up
      result
  
  write data/ByteArray:
    result = data

  read -> ByteArray:
    return characteristic.read
  
  is_encrypted -> bool:
    return encrypted_

  lock_host_read -> none:
    sem.down
  
  unlock_host_read -> none:
    sem.up
  
  close:
    if recv_task:
      recv_task.cancel
      recv_task = null

class BLEService_:
  uuid/ByteArray
  name/string

  characteristics/Map
  peripheral/ble.Peripheral

  static CHARACTERISTICS ::= [
    {"name":"prov-scan",    "id":0x50, "encrypted":true},
    {"name":"prov-session", "id":0x51, "encrypted":false},
    {"name":"prov-config",  "id":0x52, "encrypted":true},
    {"name":"proto-ver",    "id":0x53, "encrypted":false},
    {"name":"custom-data",  "id":0x54, "encrypted":true}
  ]

  constructor .uuid/ByteArray .name/string:
    adapter := ble.Adapter
    peripheral = adapter.peripheral
    service := peripheral.add_service
        ble.BleUuid uuid

    characteristics = Map
    CHARACTERISTICS.do:
      characteristics[it["name"]] =
          BLECharacteristic_
              service
              uuid
              it["id"]
              it["name"]
              it["encrypted"]

    service.deploy

  start:
    peripheral.start_advertise
        ble.AdvertisementData
            --name=name
            --service_classes=[ble.BleUuid uuid]
            --flags=ble.BLE_ADVERTISE_FLAGS_GENERAL_DISCOVERY |
                    ble.BLE_ADVERTISE_FLAGS_BREDR_UNSUPPORTED
        --interval=Duration --ms=160
        --connection_mode=ble.BLE_CONNECT_MODE_UNDIRECTIONAL
  
  operator [] name/string -> BLECharacteristic_:
    return characteristics[name]

  close:
    characteristics.do: | key value |
      value.close

interface Security_:
  encrypt data/ByteArray -> ByteArray
  decrypt data/ByteArray -> ByteArray
  handshake data/ByteArray -> ByteArray
  version -> int

class Security0_ implements Security_:
  static SESSION_0 ::= 10 /** type: message */
  static SESSION_0_MSG ::= 1 /** type: enum */
  static SESSION_0_REQ ::= 20 /** type: message */
  static SESSION_0_RESP ::= 21 /** type: message */

  process_msg r/protobuf.Reader -> ByteArray:
    r.read_message:
      r.read_field SESSION_0_REQ:
        r.read_primitive protobuf.PROTOBUF_TYPE_BYTES

    resp_msg := {
      SESSION_0: {
        SESSION_0_MSG: 1 /** 1: no need encryption */
      }
    }

    return protobuf_map_to_bytes_ --message=resp_msg

  handshake data/ByteArray -> ByteArray:
    resp := #[]

    r := protobuf.Reader data
    r.read_message:
      r.read_field SESSION_0:
        return process_msg r

    return resp

  encrypt data/ByteArray -> ByteArray:
    return data

  decrypt data/ByteArray -> ByteArray:
    return data
  
  version -> int:
    return 0

class Security2_ implements Security_:
  static SESSION_VER ::= 2 /** type: enum */
  static SESSION_VER_SEC_2 ::= 2 /** security mode 2 */

  static SESSION_2 ::= 10 /** type: message */
  static SESSION_2_MSG ::= 12 /** type: enum */
  static SESSION_2_MSG_REQ_0 ::= 20 /** type: message */
  static SESSION_2_MSG_RESP_0 ::= 21 /** type: message */
  static SESSION_2_MSG_REQ_1 ::= 22 /** type: message */
  static SESSION_2_MSG_RESP_1 ::= 23 /** type: message */

  static SESSION_2_MSG_ID ::= 1 /** type: enum */
  static SESSION_2_MSG_ID_REQ_0 ::= 0 /** type: enum */
  static SESSION_2_MSG_ID_RESP_0 ::= 1 /** type: enum */
  static SESSION_2_MSG_ID_REQ_1 ::= 2 /** type: enum */
  static SESSION_2_MSG_ID_RESP_1 ::= 3 /** type: enum */

  static SESSION_2_REQ_0_USER_NAME ::= 1 /** type: bytes */
  static SESSION_2_REQ_0_PUBLIC_KEY ::= 2 /** type: bytes */

  static SESSION_2_RESP_0_STATUS ::= 1 /** type: enum */
  static SESSION_2_RESP_0_PUBLIC_KEY ::= 2 /** type: bytes */
  static SESSION_2_RESP_0_SALT ::= 3 /** type: bytes */

  static SESSION_2_REQ_1_CLIENT_PROOF ::= 1 /** type: bytes */

  static SESSION_2_RESP_1_STATUS ::= 1 /** type: enum */
  static SESSION_2_RESP_1_DEVICE_PROOF ::= 2 /** type: bytes */
  static SESSION_2_RESP_1_DEVICE_NONCE ::= 3 /** type: bytes */

  salt_/ByteArray

  srp_/SRP
  session_key_/ByteArray := #[]
  user_name_/ByteArray := #[]
  aes_gcm_iv_/ByteArray := ByteArray 12: random

  constructor .salt_/ByteArray verifier/ByteArray:
    srp_ = SRP salt_ verifier

  process_msg r/protobuf.Reader -> ByteArray:
    msg_id := null
    public_key/ByteArray := #[]
    client_proof/ByteArray := #[]

    r.read_message:
      r.read_field SESSION_2_MSG_ID:
        r.read_primitive protobuf.PROTOBUF_TYPE_INT32
      r.read_field SESSION_2_MSG_REQ_0:
        msg_id = SESSION_2_MSG_ID_REQ_0
        r.read_message:
          r.read_field SESSION_2_REQ_0_USER_NAME:
            user_name_ = r.read_primitive protobuf.PROTOBUF_TYPE_BYTES
          r.read_field SESSION_2_REQ_0_PUBLIC_KEY:
            public_key = r.read_primitive protobuf.PROTOBUF_TYPE_BYTES
      r.read_field SESSION_2_MSG_REQ_1:
        msg_id = SESSION_2_MSG_ID_REQ_1
        r.read_message:
          r.read_field SESSION_2_REQ_1_CLIENT_PROOF:
            client_proof = r.read_primitive protobuf.PROTOBUF_TYPE_BYTES

    if msg_id == SESSION_2_MSG_ID_REQ_0:
      session_key_ = srp_.get_session_key public_key

      resp_msg := {
        SESSION_VER: SESSION_VER_SEC_2,
        SESSION_2_MSG: {
          SESSION_2_MSG_ID : SESSION_2_MSG_ID_RESP_0,
          SESSION_2_MSG_RESP_0: {
            SESSION_2_RESP_0_PUBLIC_KEY: srp_.gen_service_public_key,
            SESSION_2_RESP_0_SALT: salt_
          }
        }
      }

      return protobuf_map_to_bytes_ --message=resp_msg
    else if msg_id == SESSION_2_MSG_ID_REQ_1:
      device_proof := srp_.exchange_proofs user_name_ client_proof

      resp_msg := {
        SESSION_VER: SESSION_VER_SEC_2,
        SESSION_2_MSG: {
          SESSION_2_MSG_ID : SESSION_2_MSG_ID_RESP_1,
          SESSION_2_MSG_RESP_1: {
            SESSION_2_RESP_1_DEVICE_PROOF: device_proof,
            SESSION_2_RESP_1_DEVICE_NONCE: aes_gcm_iv_
          }
        }
      }

      return protobuf_map_to_bytes_ --message=resp_msg
    else:
      return #[]

  handshake data/ByteArray -> ByteArray:
    resp := #[]

    r := protobuf.Reader data
    r.read_message:
      r.read_field SESSION_VER:
        r.read_primitive protobuf.PROTOBUF_TYPE_INT32
      r.read_field SESSION_2_MSG:
        return process_msg r

    return resp

  encrypt data/ByteArray -> ByteArray:
    return (AesGcm.encryptor session_key_[0..32] aes_gcm_iv_).encrypt data

  decrypt data/ByteArray -> ByteArray:
    return (AesGcm.decryptor session_key_[0..32] aes_gcm_iv_).decrypt data
  
  version -> int:
    return 2

interface Process_:
  run data/ByteArray -> ByteArray

class VerProcess_ implements Process_:
  static VERSION := "v1.1"
  static BASE_CAPS := ["wifi_scan"]

  resp_msg/ByteArray

  constructor version/int:
    caps := List BASE_CAPS.size: BASE_CAPS[it]
    if version == 0:
      caps.add "no_sec"
    ver_map := {"prov":{"ver":VERSION, "sec_ver":version, "cap":caps}}
    resp_msg = json.encode ver_map

  run data/ByteArray -> ByteArray:
    return resp_msg

class SessionProcess_ implements Process_:
  security_/Security_

  constructor .security_/Security_:

  run data/ByteArray -> ByteArray:
    return security_.handshake data

class ScanProcess_ implements Process_:
  static MSG ::= 1 /** type: enum */

  /** Message enum number */
  static MSG_REQ_START ::= 0
  static MSG_RESP_START ::= 1
  static MSG_REQ_STATUS ::= 2
  static MSG_RESP_STATUS ::= 3
  static MSG_REQ_RESULT ::= 4
  static MSG_RESP_RESULT ::= 5

  static REQ_START ::= 10 /** type: message */
  static REQ_START_BLOCK ::= 1 /** type: bool */
  static REQ_START_PERIOD ::= 4 /** type: uint32 */

  static REQ_STATUS ::= 12 /** type: message */

  static RESP_STATUS ::= 13 /** type: message */
  static RESP_STATUS_FINISHED ::= 1 /** type: bool */
  static RESP_STATUS_COUNT ::= 2 /** type: uint32 */

  static REQ_RESULT ::= 14 /** type: message */
  static REQ_RESULT_START ::= 1 /** type: uint32 */
  static REQ_RESULT_COUNT ::= 2 /** type: uint32 */

  static RESP_RESULT ::= 15 /** type: message */
  static RESP_RESULT_ENTRIES ::= 1 /** type: Repeated message */
  static RESP_RESULT_ENTRIES_SSID ::= 1 /** type: bytes */
  static RESP_RESULT_ENTRIES_CHANNEL ::= 2 /** type: uint32 */
  static RESP_RESULT_ENTRIES_RSSI ::= 3 /** type: int32_t */
  static RESP_RESULT_ENTRIES_BSSID ::= 4 /** type: bytes */
  static RESP_RESULT_ENTRIES_AUTH ::= 5 /** type: uint32 */

  static CHANNEL_NUM ::= 14
  static SCAN_AP_MAX ::= 16

  ap_list/List := List
  scan_done/bool := false
  report_count/int := 4
  scan_period/int := 120
  msg_offset/int := 0

  compare_ap_by_rssi a/wifi.AccessPoint b/wifi.AccessPoint -> int:
    return -(a.rssi.compare_to b.rssi)

  init_parameters -> none:
    ap_list = List
    scan_done = false
    report_count = 4
    scan_period = 120
    msg_offset = 0

  scan_task:
    channels := ByteArray CHANNEL_NUM: it + 1
    ap_list = wifi.scan
        channels
        --period_per_channel_ms=scan_period
    ap_list.sort --in_place:
      | a b | compare_ap_by_rssi a b
    size := min ap_list.size SCAN_AP_MAX
    ap_list = ap_list[..size]
    scan_done = true

  scan_start r/protobuf.Reader -> ByteArray:
    r.read_message:
      r.read_field REQ_START_BLOCK:
        /** block=true is not supported, because it blocks NimBLE system task. */
        block := r.read_primitive protobuf.PROTOBUF_TYPE_INT32
      r.read_field REQ_START_PERIOD:
        scan_period = r.read_primitive protobuf.PROTOBUF_TYPE_INT32

    init_parameters
    scan_task

    resp_msg := {
        MSG: MSG_RESP_START
    }
    return protobuf_map_to_bytes_ --message=resp_msg
  
  scan_status -> ByteArray:
    buffer := bytes.Buffer
    w := protobuf.Writer buffer

    resp_msg := {
        MSG: MSG_RESP_STATUS,
        RESP_STATUS: {:}
    }

    if not scan_done:
      resp_msg[RESP_STATUS][RESP_STATUS_FINISHED] = 0
    else:
      resp_msg[RESP_STATUS][RESP_STATUS_FINISHED] = 1
      resp_msg[RESP_STATUS][RESP_STATUS_COUNT] = ap_list.size

    return protobuf_map_to_bytes_ --message=resp_msg
  
  scan_result r/protobuf.Reader -> ByteArray:
    r.read_message:
        r.read_field REQ_RESULT_COUNT:
          report_count = r.read_primitive protobuf.PROTOBUF_TYPE_INT32

    ap_info_msg := List
    if msg_offset < ap_list.size:
      ap_num := min (ap_list.size - msg_offset) report_count
      ap_num.repeat:
        ap ::= ap_list[msg_offset + it]
        ap_info := {
          RESP_RESULT_ENTRIES_SSID: ap.ssid,
          RESP_RESULT_ENTRIES_CHANNEL: ap.channel,
          RESP_RESULT_ENTRIES_RSSI: ap.rssi,
          RESP_RESULT_ENTRIES_BSSID: ap.bssid,
          RESP_RESULT_ENTRIES_AUTH: ap.authmode,
        }
        ap_info_msg.add ap_info

      msg_offset += ap_num

    resp_msg := {
      MSG: MSG_RESP_RESULT,
      RESP_RESULT: {
        RESP_RESULT_ENTRIES: ap_info_msg
      }
    }
    return protobuf_map_to_bytes_ --message=resp_msg

  run data/ByteArray -> ByteArray:
    resp := #[]
    
    r := protobuf.Reader data
    r.read_message:
      r.read_field MSG:
        msgid := r.read_primitive protobuf.PROTOBUF_TYPE_INT32
        if msgid == 2:
          resp = scan_status
      r.read_field REQ_START:
        resp = scan_start r
      r.read_field REQ_STATUS:
        r.read_primitive protobuf.PROTOBUF_TYPE_BYTES
        resp = scan_status
      r.read_field REQ_RESULT:
        resp = scan_result r

    return resp

class ConfigProcess_ implements Process_:
  static MSG ::= 1 /** type: enum */

  /** Message enum number */
  static MSG_REQ_STATUS ::= 0
  static MSG_RESP_STATUS ::= 1
  static MSG_SET_CONFIG ::= 2
  static MSG_RESP_CONFIG ::= 3
  static MSG_SET_APPLY ::= 4
  static MSG_RESP_APPY ::= 5

  static REQ_STATUS ::= 10 /** type: message */

  static RESP_STATUS ::= 11 /** type: message */
  static RESP_STATUS_CONNECTED ::= 11 /** type: message */
  static RESP_STATUS_CONNECTED_IPV4_ADDR ::= 1 /** type: string */
  static RESP_STATUS_CONNECTED_AUTH_MODE ::= 2 /** type: uint32 */
  static RESP_STATUS_CONNECTED_SSID ::= 3 /** type: bytes */
  static RESP_STATUS_CONNECTED_BSSID ::= 4 /** type: bytes */
  static RESP_STATUS_CONNECTED_CHANNEL ::= 5 /** type: uint32 */

  static SET_CONFIG ::= 12 /** type: message */
  static SET_CONFIG_SSID ::= 1 /** type: bytes */
  static SET_CONFIG_PASSWORD ::= 2 /** type: bytes */

  static REQ_APPLY ::= 14 /** type: message */

  ssid/string := ""
  password/string := ""
  network := null

  recv_request_status/bool := false

  is_done -> bool:
    return recv_request_status

  set_config r/protobuf.Reader -> ByteArray:
    r.read_message:
      r.read_field SET_CONFIG_SSID:
        ssid = r.read_primitive protobuf.PROTOBUF_TYPE_STRING
      r.read_field SET_CONFIG_PASSWORD:
        password = r.read_primitive protobuf.PROTOBUF_TYPE_STRING
    
    resp_msg := {
      MSG: MSG_RESP_CONFIG
    }
    return protobuf_map_to_bytes_ --message=resp_msg

  set_apply -> ByteArray:
    network = wifi.open
        --ssid=ssid
        --password=password

    resp_msg := {
        MSG: MSG_RESP_APPY
    }
    return protobuf_map_to_bytes_ --message=resp_msg 

  req_status -> ByteArray:
    ap ::= network.access_point

    resp_msg := {
      MSG: MSG_RESP_STATUS,
      RESP_STATUS: {
        RESP_STATUS_CONNECTED: {
          RESP_STATUS_CONNECTED_IPV4_ADDR: "$(network.address)",
          RESP_STATUS_CONNECTED_AUTH_MODE: ap.authmode,
          RESP_STATUS_CONNECTED_SSID: ap.ssid,
          RESP_STATUS_CONNECTED_BSSID: ap.bssid,
          RESP_STATUS_CONNECTED_CHANNEL: ap.channel,
        }
      }
    }
    return protobuf_map_to_bytes_ --message=resp_msg  

  run data/ByteArray -> ByteArray:
    resp := #[]

    r := protobuf.Reader data
    r.read_message:
      r.read_field MSG:
        msgid := r.read_primitive protobuf.PROTOBUF_TYPE_INT32
        if msgid == MSG_SET_APPLY:
          resp = set_apply
      r.read_field SET_CONFIG:
        resp = set_config r
      r.read_field REQ_STATUS:
        r.read_primitive protobuf.PROTOBUF_TYPE_BYTES
        resp = req_status
        recv_request_status = true
      r.read_field REQ_APPLY:
        r.read_primitive protobuf.PROTOBUF_TYPE_BYTES
        resp = set_apply

    return resp

class Provision:
  service_/BLEService_ := ?
  security_/Security_ := ?
  version_task_/Task? := null
  config_task_/Task? := null
  session_task_/Task? := null
  scan_task_/Task? := null
  latch_ := monitor.Latch

  constructor.ble service_name/string security/Security_:
    return Provision.ble_with_uuid SERVICE_UUID service_name security
  
  constructor.ble_with_uuid service_uuid/ByteArray service_name/string .security_/Security_:
    service_ = BLEService_ service_uuid service_name

  start -> none:
    if version_task_: throw "Already running"
    if latch_.has_value: throw "CLOSED"
    version_task_ = task:: ch_version_task_
    config_task_ = task:: ch_config_task_
    session_task_ = task:: ch_session_task_
    scan_task_ = task:: ch_scan_task_

    service_.start

  wait -> bool:
    return latch_.get

  static common_process_ security/Security_ process/Process_ characteristic/BLECharacteristic_:
    encrypt_data := characteristic.read
    characteristic.lock_host_read
    encrypted := characteristic.is_encrypted
    data := encrypted ? security.decrypt encrypt_data : encrypt_data
    resp := process.run data
    if resp.size > 0:
      data = encrypted ? security.encrypt resp : resp
      characteristic.write data
    characteristic.unlock_host_read

  ch_version_task_:
    characteristic := service_["proto-ver"]
    ver_process := VerProcess_ security_.version
    common_process_ security_ ver_process characteristic

  ch_session_task_:
    characteristic := service_["prov-session"]
    session_process := SessionProcess_ security_
    while true:
      common_process_ security_ session_process characteristic

  ch_scan_task_:
    characteristic := service_["prov-scan"]
    scan_process := ScanProcess_
    while true:
      common_process_ security_ scan_process characteristic

  ch_config_task_:
    characteristic := service_["prov-config"]
    config_process := ConfigProcess_
    while true:
      common_process_ security_ config_process characteristic
      if config_process.is_done:
        /**
        sleep for 1 seconds to wait for host tool or phone APP checking state and disconnecting
        */
        sleep --ms=1000
        latch_.set true
  /**
  Closes the provisioning and shuts down the service.
  */
  close:
    if version_task_:
      version_task_.cancel
      version_task_ = null
    if session_task_:
      session_task_.cancel
      session_task_ = null
    if scan_task_:
      scan_task_.cancel
      scan_task_ = null
    if config_task_:
      config_task_.cancel
      config_task_ = null
    
    service_.close

    if not latch_.has_value: latch_.set false

protobuf_map_to_bytes_ --message/Map /** field:value */ -> ByteArray:
  buffer := bytes.Buffer
  w := protobuf.Writer buffer

  message.do: | key value |
    if key is not int:
      throw "WRONG_OBJECT_TYPE"
    if value is int:
      w.write_primitive protobuf.PROTOBUF_TYPE_INT32 value --as_field=key --oneof=true
    else if value is string:
      w.write_primitive protobuf.PROTOBUF_TYPE_STRING value --as_field=key
    else if value is ByteArray:
      w.write_primitive protobuf.PROTOBUF_TYPE_BYTES value --as_field=key
    else if value is List:
      id := key
      value.do:
        w.write_primitive
            protobuf.PROTOBUF_TYPE_BYTES
            protobuf_map_to_bytes_ --message=it
            --as_field=id
    else if value is Map:
      w.write_primitive 
          protobuf.PROTOBUF_TYPE_BYTES
          protobuf_map_to_bytes_ --message=value
          --as_field=key
    else:
      throw "WRONG_OBJECT_TYPE"

  return buffer.bytes

get_mac_address -> ByteArray:
  // TODO: don't use a primitive.
  #primitive.esp32.get_mac_address
