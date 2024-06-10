import net.wifi
import protobuf

import .ble show Process_
import .utils
import ..proto_.constants-pb
import ..proto_.wifi-scan-pb

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
