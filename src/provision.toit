// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import bytes
import encoding.json
import monitor
import net.wifi
import ble
import crypto.aes show *
import protobuf
import .srp
import .proto.session_pb
import .proto.sec0_pb
import .proto.sec2_pb
import .proto.constants_pb
import .proto.wifi_scan_pb
import .proto.wifi_config_pb
import .proto.wifi_constants_pb

/** This UUID is used in PC and Phone APP by default. */
SERVICE_UUID ::= #[0x02, 0x1a, 0x90, 0x04, 0x03, 0x82, 0x4a, 0xea,
                   0xbf, 0xf4, 0x6b, 0x3f, 0x1c, 0x5a, 0xdf, 0xb4]

/** This security mode 0 doesn't encrypt/decrypt. */
SECURITY0 := Security0_

/** This security mode 2 use SRP6a + AES-GCM. */
security2 --salt/ByteArray --verifier/ByteArray -> Security:
  return Security2_ salt verifier

class BLECharacteristic_:
  characteristic/ble.LocalCharacteristic
  is_encrypted/bool
  desc/string
  recv_task/Task? := null
  result/ByteArray := #[]
  mutex_ := monitor.Mutex

  static UUID_BASE ::= 0xff
  static READ_TIMEOUT_MS ::= 10 * 1000
  static PROPERTIES ::= ble.CHARACTERISTIC_PROPERTY_READ | ble.CHARACTERISTIC_PROPERTY_WRITE
  static PERMISSIONS ::= ble.CHARACTERISTIC_PERMISSION_READ | ble.CHARACTERISTIC_PERMISSION_WRITE
  static DESC_UUID ::= ble.BleUuid #[0x00, 0x00, 0x29, 0x01, 0x00, 0x00, 0x10, 0x00,
                                     0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb]

  constructor service/ble.LocalService service_uuid/ByteArray id/int .desc/string .is_encrypted/bool:
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
      mutex_.do:
        result
  
  write data/ByteArray:
    result = data

  read -> ByteArray:
    return characteristic.read

  mutex_do [block]:
    mutex_.do:
      block.call
  
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
    characteristics.do: | _ value |
      value.close

interface Security:
  encrypt data/ByteArray -> ByteArray
  decrypt data/ByteArray -> ByteArray
  handshake data/ByteArray -> ByteArray
  version -> int

class Security0_ implements Security:

  handshake data/ByteArray -> ByteArray:
    resp_msg := null

    session := SessionData.deserialize (protobuf.Reader data)
    if session.sec_ver != version:
      throw "Session version does not match"

    ses0 := session.proto_sec0
    if ses0.msg == Sec0MsgType_S0_Session_Command:
      resp_msg = SessionData
          --sec_ver=version
          --proto_sec0=Sec0Payload
              --msg=Sec0MsgType_S0_Session_Response
              --payload_sr=S0SessionResp
                  --status=Status_Success
    else:
      throw "Session 0 message is not supported"

    return protobuf_message_to_bytes_ resp_msg

  encrypt data/ByteArray -> ByteArray:
    return data

  decrypt data/ByteArray -> ByteArray:
    return data
  
  version -> int:
    return SecSchemeVersion_SecScheme0

class Security2_ implements Security:
  salt_/ByteArray

  srp_/SRP
  session_key_/ByteArray := #[]
  user_name_/ByteArray := #[]
  // TODO(florian): use a cryptographic random function.
  aes_gcm_iv_/ByteArray := ByteArray 12: random

  constructor .salt_/ByteArray verifier/ByteArray:
    srp_ = SRP salt_ verifier

  handshake data/ByteArray -> ByteArray:
    resp_msg := null

    session := SessionData.deserialize (protobuf.Reader data)
    if session.sec_ver != version:
      throw "Session version does not match"

    ses2 := session.proto_sec2
    if ses2.msg == Sec2MsgType_S2Session_Command0:
      user_name_ = ses2.payload_sc0.client_username
      session_key_ = srp_.get_session_key ses2.payload_sc0.client_pubkey

      resp_msg = SessionData
          --sec_ver=version
          --proto_sec2=Sec2Payload
              --msg=Sec2MsgType_S2Session_Response0
              --payload_sr0=S2SessionResp0
                  --status=Status_Success
                  --device_pubkey=srp_.gen_service_public_key
                  --device_salt=salt_
    else if ses2.msg == Sec2MsgType_S2Session_Command1:
      device_proof := srp_.exchange_proofs user_name_ ses2.payload_sc1.client_proof

      resp_msg = SessionData
          --sec_ver=version
          --proto_sec2=Sec2Payload
              --msg=Sec2MsgType_S2Session_Response1
              --payload_sr1=S2SessionResp1
                  --status=Status_Success
                  --device_proof=device_proof
                  --device_nonce=aes_gcm_iv_
    else:
      throw "Session 2 message is not supported"

    return protobuf_message_to_bytes_ resp_msg

  encrypt data/ByteArray -> ByteArray:
    /**
    session_key_ is generated by SHA512, so its length is 512 bits(64 bytes),
    but AES-GCM's key length is 256 bits(32 bytes).
    */
    return (AesGcm.encryptor session_key_[..32] aes_gcm_iv_).encrypt data

  decrypt data/ByteArray -> ByteArray:
    return (AesGcm.decryptor session_key_[..32] aes_gcm_iv_).decrypt data
  
  version -> int:
    return SecSchemeVersion_SecScheme2

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
  security_/Security

  constructor .security_/Security:

  run data/ByteArray -> ByteArray:
    return security_.handshake data

class ScanProcess_ implements Process_:
  static CHANNEL_NUM ::= 14
  static SCAN_AP_MAX ::= 16

  ap_list/List := []

  compare_ap_by_rssi a/wifi.AccessPoint b/wifi.AccessPoint -> int:
    return -(a.rssi.compare_to b.rssi)

  run data/ByteArray -> ByteArray:
    resp_msg := null
    
    scan := WiFiScanPayload.deserialize (protobuf.Reader data)
    if scan.msg == WiFiScanMsgType_TypeCmdScanStart:
      scan_start := scan.payload_cmd_scan_start

      channels := ByteArray CHANNEL_NUM: it + 1
      ap_list = wifi.scan
          channels
          --period_per_channel_ms=scan_start.period_ms
      ap_list.sort --in_place:
        | a b | compare_ap_by_rssi a b
      size := min ap_list.size SCAN_AP_MAX
      ap_list = ap_list[..size]

      resp_msg = WiFiScanPayload
          --msg=WiFiScanMsgType_TypeRespScanStart
          --status=Status_Success
          --payload_resp_scan_start=RespScanStart
    else if scan.msg == WiFiScanMsgType_TypeCmdScanStatus:
      resp_msg = WiFiScanPayload
          --msg=WiFiScanMsgType_TypeRespScanStart
          --status=Status_Success
          --payload_resp_scan_status=RespScanStatus
              --scan_finished=(ap_list.size > 0)
              --result_count=ap_list.size
    else if scan.msg == WiFiScanMsgType_TypeCmdScanResult:
      arg := scan.payload_cmd_scan_result
      scan_ap := ap_list[arg.start_index..arg.start_index+arg.count]

      ap_entries := []
      scan_ap.do: |ap/wifi.AccessPoint|
        ap_entries.add 
            WiFiScanResult
              --ssid=ap.ssid.to_byte_array
              --channel=ap.channel
              --rssi=ap.rssi
              --bssid=ap.bssid
              --auth=ap.authmode
 
      resp_msg = WiFiScanPayload
          --msg=WiFiScanMsgType_TypeRespScanResult
          --status=Status_Success
          --payload_resp_scan_result=RespScanResult
              --entries=ap_entries
    else:
      throw "Scan message is not supported"

    return protobuf_message_to_bytes_ resp_msg

class ConfigProcess_ implements Process_:
  ssid/string := ""
  password/string := ""
  network := null
  is_done/bool := false

  run data/ByteArray -> ByteArray:
    resp_msg := null

    wifi_config := WiFiConfigPayload.deserialize (protobuf.Reader data)
    if wifi_config.msg == WiFiConfigMsgType_TypeCmdSetConfig:
      arg := wifi_config.payload_cmd_set_config
      ssid = arg.ssid.to_string
      password = arg.passphrase.to_string

      resp_msg = WiFiConfigPayload
          --msg=WiFiConfigMsgType_TypeRespSetConfig
          --payload_resp_set_config=RespSetConfig
              --status=Status_Success
    else if wifi_config.msg == WiFiConfigMsgType_TypeCmdApplyConfig:
      network = wifi.open
          --ssid=ssid
          --password=password

      resp_msg = WiFiConfigPayload
          --msg=WiFiConfigMsgType_TypeRespApplyConfig
          --payload_resp_apply_config=RespApplyConfig
              --status=Status_Success
    else if wifi_config.msg == WiFiConfigMsgType_TypeCmdGetStatus:
      ap/wifi.AccessPoint ::= network.access_point

      resp_msg = WiFiConfigPayload
          --msg=WiFiConfigMsgType_TypeRespGetStatus
          --payload_resp_get_status=RespGetStatus
              --status=Status_Success
              --state_connected=WifiConnectedState
                  --ip4_addr="$(network.address)"
                  --auth_mode=ap.authmode
                  --ssid=ap.ssid.to_byte_array
                  --bssid=ap.bssid
                  --channel=ap.channel
      is_done = true
    else:
      throw "WiFi config message is not supported"

    return protobuf_message_to_bytes_ resp_msg

class Provision:
  service_/BLEService_ := ?
  security_/Security := ?
  version_task_/Task? := null
  config_task_/Task? := null
  session_task_/Task? := null
  scan_task_/Task? := null
  latch_ := monitor.Latch

  constructor.ble service_name/string security/Security:
    return Provision.ble_with_uuid SERVICE_UUID service_name security
  
  constructor.ble_with_uuid service_uuid/ByteArray service_name/string .security_/Security:
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

  static common_process_ security/Security process/Process_ characteristic/BLECharacteristic_:
    encrypt_data := characteristic.read
    characteristic.mutex_do:
      encrypted := characteristic.is_encrypted
      data := encrypted ? security.decrypt encrypt_data : encrypt_data
      resp := process.run data
      if resp.size > 0:
        data = encrypted ? security.encrypt resp : resp
        characteristic.write data

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

protobuf_message_to_bytes_ message/protobuf.Message -> ByteArray:
  buffer := bytes.Buffer
  w := protobuf.Writer buffer
  message.serialize w
  return buffer.bytes

get_mac_address -> ByteArray:
  // TODO: don't use a primitive.
  #primitive.esp32.get_mac_address
