import encoding.json
import .ble show Process_

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

