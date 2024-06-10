import encoding.json
import monitor
import net.wifi
import ble
import io
import protobuf

import .utils

/** This UUID is used in PC and Phone APP by default. */
SERVICE-UUID ::= #[0x02, 0x1a, 0x90, 0x04, 0x03, 0x82, 0x4a, 0xea,
                   0xbf, 0xf4, 0x6b, 0x3f, 0x1c, 0x5a, 0xdf, 0xb4]

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

interface Process_:
  run data/ByteArray -> ByteArray
