// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import encoding.json
import monitor
import net.wifi
import ble
import crypto.aes show *
import io
import protobuf
import .srp
import .proto.session-pb
import .proto.sec0-pb
import .proto.sec2-pb
import .proto.constants-pb
import .proto.wifi-scan-pb
import .proto.wifi-config-pb
import .proto.wifi-constants-pb

/** This UUID is used in PC and Phone APP by default. */
SERVICE-UUID ::= #[0x02, 0x1a, 0x90, 0x04, 0x03, 0x82, 0x4a, 0xea,
                   0xbf, 0xf4, 0x6b, 0x3f, 0x1c, 0x5a, 0xdf, 0xb4]

/** This security mode 0 doesn't encrypt/decrypt. */
SECURITY0 := Security0_

/** This security mode 2 use SRP6a + AES-GCM. */
security2 --salt/ByteArray --verifier/ByteArray -> Security:
  return Security2_ salt verifier

class BLECharacteristic_:
  characteristic/ble.LocalCharacteristic
  is-encrypted/bool
  desc/string
  recv-task/Task? := null
  result/ByteArray := #[]
  mutex_ := monitor.Mutex

  static UUID-BASE ::= 0xff
  static READ-TIMEOUT-MS ::= 10 * 1000
  static PROPERTIES ::= ble.CHARACTERISTIC-PROPERTY-READ | ble.CHARACTERISTIC-PROPERTY-WRITE
  static PERMISSIONS ::= ble.CHARACTERISTIC-PERMISSION-READ | ble.CHARACTERISTIC-PERMISSION-WRITE
  static DESC-UUID ::= ble.BleUuid #[0x00, 0x00, 0x29, 0x01, 0x00, 0x00, 0x10, 0x00,
                                     0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb]

  constructor service/ble.LocalService service-uuid/ByteArray id/int .desc/string .is-encrypted/bool:
    uuid := service-uuid.copy
    uuid[2] = UUID-BASE
    uuid[3] = id

    characteristic = service.add-characteristic
        ble.BleUuid uuid
        --properties=PROPERTIES
        --permissions=PERMISSIONS
        --read-timeout-ms=READ-TIMEOUT-MS
    characteristic.add-descriptor
        DESC-UUID
        PROPERTIES
        PERMISSIONS
        desc.to-byte-array

    recv-task = task:: recv-task-run

  recv-task-run:
    characteristic.handle-read-request:
      mutex_.do:
        result

  write data/ByteArray:
    result = data

  read -> ByteArray:
    return characteristic.read

  mutex-do [block]:
    mutex_.do:
      block.call

  close:
    if recv-task:
      recv-task.cancel
      recv-task = null

class BLEService_:
  uuid/ByteArray
  name/string

  characteristics/Map? := ?
  service/ble.LocalService? := ?
  peripheral/ble.Peripheral? := ?
  adapter/ble.Adapter? := ?

  static CHARACTERISTICS ::= [
    {"name":"prov-scan",    "id":0x50, "encrypted":true},
    {"name":"prov-session", "id":0x51, "encrypted":false},
    {"name":"prov-config",  "id":0x52, "encrypted":true},
    {"name":"proto-ver",    "id":0x53, "encrypted":false},
    {"name":"custom-data",  "id":0x54, "encrypted":true}
  ]

  constructor .uuid/ByteArray .name/string:
    adapter = ble.Adapter
    peripheral = adapter.peripheral
    service = peripheral.add-service
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

    peripheral.deploy

  start:
    peripheral.start-advertise
        ble.AdvertisementData
            --name=name
            --service-classes=[ble.BleUuid uuid]
            --flags=ble.BLE-ADVERTISE-FLAGS-GENERAL-DISCOVERY |
                    ble.BLE-ADVERTISE-FLAGS-BREDR-UNSUPPORTED
        --interval=Duration --ms=160
        --connection-mode=ble.BLE-CONNECT-MODE-UNDIRECTIONAL

  operator [] name/string -> BLECharacteristic_:
    return characteristics[name]

  close:
    if characteristics:
      characteristics.do: | _ value |
        value.close
      characteristics = null
    if peripheral:
      peripheral.close
      peripheral = null
    if adapter:
      adapter.close
      adapter = null

interface Security:
  encrypt data/ByteArray -> ByteArray
  decrypt data/ByteArray -> ByteArray
  handshake data/ByteArray -> ByteArray
  version -> int

class Security0_ implements Security:

  handshake data/ByteArray -> ByteArray:
    resp-msg := null

    session := SessionData.deserialize (protobuf.Reader data)
    if session.sec-ver != version:
      throw "Session version does not match"

    ses0 := session.proto-sec0
    if ses0.msg == Sec0MsgType-S0-Session-Command:
      resp-msg = SessionData
          --sec-ver=version
          --proto-sec0=Sec0Payload
              --msg=Sec0MsgType-S0-Session-Response
              --payload-sr=S0SessionResp
                  --status=Status-Success
    else:
      throw "Session 0 message is not supported"

    return protobuf-message-to-bytes_ resp-msg

  encrypt data/ByteArray -> ByteArray:
    return data

  decrypt data/ByteArray -> ByteArray:
    return data

  version -> int:
    return SecSchemeVersion-SecScheme0

class Security2_ implements Security:
  salt_/ByteArray

  srp_/SRP
  session-key_/ByteArray := #[]
  user-name_/ByteArray := #[]
  // TODO(florian): use a cryptographic random function.
  aes-gcm-iv_/ByteArray := ByteArray 12: random

  constructor .salt_/ByteArray verifier/ByteArray:
    srp_ = SRP salt_ verifier

  handshake data/ByteArray -> ByteArray:
    resp-msg := null

    session := SessionData.deserialize (protobuf.Reader data)
    if session.sec-ver != version:
      throw "Session version does not match"

    ses2 := session.proto-sec2
    if ses2.msg == Sec2MsgType-S2Session-Command0:
      user-name_ = ses2.payload-sc0.client-username
      session-key_ = srp_.get-session-key ses2.payload-sc0.client-pubkey

      resp-msg = SessionData
          --sec-ver=version
          --proto-sec2=Sec2Payload
              --msg=Sec2MsgType-S2Session-Response0
              --payload-sr0=S2SessionResp0
                  --status=Status-Success
                  --device-pubkey=srp_.gen-service-public-key
                  --device-salt=salt_
    else if ses2.msg == Sec2MsgType-S2Session-Command1:
      device-proof := srp_.exchange-proofs user-name_ ses2.payload-sc1.client-proof

      resp-msg = SessionData
          --sec-ver=version
          --proto-sec2=Sec2Payload
              --msg=Sec2MsgType-S2Session-Response1
              --payload-sr1=S2SessionResp1
                  --status=Status-Success
                  --device-proof=device-proof
                  --device-nonce=aes-gcm-iv_
    else:
      throw "Session 2 message is not supported"

    return protobuf-message-to-bytes_ resp-msg

  encrypt data/ByteArray -> ByteArray:
    /**
    session_key_ is generated by SHA512, so its length is 512 bits(64 bytes),
    but AES-GCM's key length is 256 bits(32 bytes).
    */
    return (AesGcm.encryptor session-key_[..32] aes-gcm-iv_).encrypt data

  decrypt data/ByteArray -> ByteArray:
    return (AesGcm.decryptor session-key_[..32] aes-gcm-iv_).decrypt data

  version -> int:
    return SecSchemeVersion-SecScheme2

interface Process_:
  run data/ByteArray -> ByteArray

class VerProcess_ implements Process_:
  static VERSION := "v1.1"
  static BASE-CAPS := ["wifi_scan"]

  resp-msg/ByteArray

  constructor version/int:
    caps := List BASE-CAPS.size: BASE-CAPS[it]
    if version == 0:
      caps.add "no_sec"
    ver-map := {"prov":{"ver":VERSION, "sec_ver":version, "cap":caps}}
    resp-msg = json.encode ver-map

  run data/ByteArray -> ByteArray:
    return resp-msg

class SessionProcess_ implements Process_:
  security_/Security

  constructor .security_/Security:

  run data/ByteArray -> ByteArray:
    return security_.handshake data

class ScanProcess_ implements Process_:
  static CHANNEL-NUM ::= 14
  static SCAN-AP-MAX ::= 16

  ap-list/List := []

  compare-ap-by-rssi a/wifi.AccessPoint b/wifi.AccessPoint -> int:
    return -(a.rssi.compare-to b.rssi)

  run data/ByteArray -> ByteArray:
    resp-msg := null

    scan := WiFiScanPayload.deserialize (protobuf.Reader data)
    if scan.msg == WiFiScanMsgType-TypeCmdScanStart:
      scan-start := scan.payload-cmd-scan-start

      channels := ByteArray CHANNEL-NUM: it + 1
      ap-list = wifi.scan
          channels
          --period-per-channel-ms=scan-start.period-ms
      ap-list.sort --in-place:
        | a b | compare-ap-by-rssi a b
      size := min ap-list.size SCAN-AP-MAX
      ap-list = ap-list[..size]

      resp-msg = WiFiScanPayload
          --msg=WiFiScanMsgType-TypeRespScanStart
          --status=Status-Success
          --payload-resp-scan-start=RespScanStart
    else if scan.msg == WiFiScanMsgType-TypeCmdScanStatus:
      resp-msg = WiFiScanPayload
          --msg=WiFiScanMsgType-TypeRespScanStart
          --status=Status-Success
          --payload-resp-scan-status=RespScanStatus
              --scan-finished=(ap-list.size > 0)
              --result-count=ap-list.size
    else if scan.msg == WiFiScanMsgType-TypeCmdScanResult:
      arg := scan.payload-cmd-scan-result
      scan-ap := ap-list[arg.start-index..arg.start-index+arg.count]

      ap-entries := []
      scan-ap.do: |ap/wifi.AccessPoint|
        ap-entries.add
            WiFiScanResult
              --ssid=ap.ssid.to-byte-array
              --channel=ap.channel
              --rssi=ap.rssi
              --bssid=ap.bssid
              --auth=ap.authmode

      resp-msg = WiFiScanPayload
          --msg=WiFiScanMsgType-TypeRespScanResult
          --status=Status-Success
          --payload-resp-scan-result=RespScanResult
              --entries=ap-entries
    else:
      throw "Scan message is not supported"

    return protobuf-message-to-bytes_ resp-msg

class ConfigProcess_ implements Process_:
  ssid/string := ""
  password/string := ""
  network := null
  is-done/bool := false

  run data/ByteArray -> ByteArray:
    resp-msg := null

    wifi-config := WiFiConfigPayload.deserialize (protobuf.Reader data)
    if wifi-config.msg == WiFiConfigMsgType-TypeCmdSetConfig:
      arg := wifi-config.payload-cmd-set-config
      ssid = arg.ssid.to-string
      password = arg.passphrase.to-string

      resp-msg = WiFiConfigPayload
          --msg=WiFiConfigMsgType-TypeRespSetConfig
          --payload-resp-set-config=RespSetConfig
              --status=Status-Success
    else if wifi-config.msg == WiFiConfigMsgType-TypeCmdApplyConfig:
      network = wifi.open
          --ssid=ssid
          --password=password

      resp-msg = WiFiConfigPayload
          --msg=WiFiConfigMsgType-TypeRespApplyConfig
          --payload-resp-apply-config=RespApplyConfig
              --status=Status-Success
    else if wifi-config.msg == WiFiConfigMsgType-TypeCmdGetStatus:
      ap/wifi.AccessPoint ::= network.access-point

      resp-msg = WiFiConfigPayload
          --msg=WiFiConfigMsgType-TypeRespGetStatus
          --payload-resp-get-status=RespGetStatus
              --status=Status-Success
              --state-connected=WifiConnectedState
                  --ip4-addr="$(network.address)"
                  --auth-mode=ap.authmode
                  --ssid=ap.ssid.to-byte-array
                  --bssid=ap.bssid
                  --channel=ap.channel
      is-done = true
    else:
      throw "WiFi config message is not supported"

    return protobuf-message-to-bytes_ resp-msg

class Provision:
  service_/BLEService_ := ?
  security_/Security := ?
  version-task_/Task? := null
  config-task_/Task? := null
  session-task_/Task? := null
  scan-task_/Task? := null
  latch_ := monitor.Latch

  constructor.ble service-name/string security/Security:
    return Provision.ble-with-uuid SERVICE-UUID service-name security

  constructor.ble-with-uuid service-uuid/ByteArray service-name/string .security_/Security:
    service_ = BLEService_ service-uuid service-name

  start -> none:
    if version-task_: throw "Already running"
    if latch_.has-value: throw "CLOSED"
    version-task_ = task:: ch-version-task_
    config-task_ = task:: ch-config-task_
    session-task_ = task:: ch-session-task_
    scan-task_ = task:: ch-scan-task_

    service_.start

  wait -> bool:
    return latch_.get

  static common-process_ security/Security process/Process_ characteristic/BLECharacteristic_:
    encrypt-data := characteristic.read
    characteristic.mutex-do:
      encrypted := characteristic.is-encrypted
      data := encrypted ? security.decrypt encrypt-data : encrypt-data
      resp := process.run data
      if resp.size > 0:
        data = encrypted ? security.encrypt resp : resp
        characteristic.write data

  ch-version-task_:
    characteristic := service_["proto-ver"]
    ver-process := VerProcess_ security_.version
    common-process_ security_ ver-process characteristic

  ch-session-task_:
    characteristic := service_["prov-session"]
    session-process := SessionProcess_ security_
    while true:
      common-process_ security_ session-process characteristic

  ch-scan-task_:
    characteristic := service_["prov-scan"]
    scan-process := ScanProcess_
    while true:
      common-process_ security_ scan-process characteristic

  ch-config-task_:
    characteristic := service_["prov-config"]
    config-process := ConfigProcess_
    while true:
      common-process_ security_ config-process characteristic
      if config-process.is-done:
        /**
        sleep for 1 seconds to wait for host tool or phone APP checking state and disconnecting
        */
        sleep --ms=1000
        latch_.set true
  /**
  Closes the provisioning and shuts down the service.
  */
  close:
    if version-task_:
      version-task_.cancel
      version-task_ = null
    if session-task_:
      session-task_.cancel
      session-task_ = null
    if scan-task_:
      scan-task_.cancel
      scan-task_ = null
    if config-task_:
      config-task_.cancel
      config-task_ = null

    service_.close

    if not latch_.has-value: latch_.set false

protobuf-message-to-bytes_ message/protobuf.Message -> ByteArray:
  buffer := io.Buffer
  w := protobuf.Writer buffer
  message.serialize w
  return buffer.bytes

get-mac-address -> ByteArray:
  // TODO: don't use a primitive.
  #primitive.esp32.get-mac-address
