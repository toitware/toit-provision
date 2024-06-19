import encoding.json
import monitor
import net.wifi
import ble
import io
import protobuf

import .config
import .scan
import .rpc
import .security
import .session
import .version

/** This UUID is used in PC and Phone APP by default. */
SERVICE-UUID ::= #[0x02, 0x1a, 0x90, 0x04, 0x03, 0x82, 0x4a, 0xea,
                   0xbf, 0xf4, 0x6b, 0x3f, 0x1c, 0x5a, 0xdf, 0xb4]

DESCRIPTOR-UUID ::= ble.BleUuid #[0x00, 0x00, 0x29, 0x01, 0x00, 0x00, 0x10, 0x00,
                                  0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb]

class BleProvision:
  name/string

  rpc-services_/List? := ?
  service/ble.LocalService? := ?
  peripheral/ble.Peripheral? := ?
  adapter/ble.Adapter? := ?

  /**
  Constructs the BLE object for provisioning.

  The $name will be shown in the app when communicating with the device.
  */
  constructor --.name
      --security-credentials/SecurityCredentials?
      --done/Lambda
      --auto-save/bool:
    adapter = ble.Adapter
    peripheral = adapter.peripheral
    service = peripheral.add-service (ble.BleUuid SERVICE-UUID)
    security := security-for --credentials=security-credentials

    rpc-services_ = [
      ScanRpcService service --security=security,
      SessionRpcService service --security=security,
      WifiConfigRpcService service --security=security --done=done --auto-save=auto-save,
      VersionRpcService service --security-version=security.version,
    ]

    peripheral.deploy

  start:
    peripheral.start-advertise
        ble.AdvertisementData
            --name=name
            --service-classes=[service.uuid]
            --flags=ble.BLE-ADVERTISE-FLAGS-GENERAL-DISCOVERY |
                    ble.BLE-ADVERTISE-FLAGS-BREDR-UNSUPPORTED
        --interval=Duration --ms=160
        --connection-mode=ble.BLE-CONNECT-MODE-UNDIRECTIONAL

  close:
    critical-do:
      if rpc-services_:
        rpc-services_.do: | service/RpcService | service.close
        rpc-services_ = null
      if peripheral:
        peripheral.close
        peripheral = null
      if adapter:
        adapter.close
        adapter = null
