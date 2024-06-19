// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import ble
import net.wifi
import protobuf

import .rpc
import .security
import ..proto_.constants-pb
import ..proto_.wifi-scan-pb

/**
An RPC service responsible for scanning for WiFi access points.
*/
class ScanRpcService extends ProtobufRpcService:
  static ID_ ::= 0x50
  static DESCRIPTION_ ::= "prov-scan"

  static CHANNEL-NUM ::= 14
  static SCAN-AP-MAX ::= 16

  /** A list of access points that have been found. */
  ap-list_/List := []

  constructor service/ble.LocalService --security/Security:
    super service ID_ --description=DESCRIPTION_ --security=security
    ap-list/List := []

  static compare-ap-by-rssi_ a/wifi.AccessPoint b/wifi.AccessPoint -> int:
    return -(a.rssi.compare-to b.rssi)

  handle-proto-request data/ByteArray -> protobuf.Message:
    scan-request := WiFiScanPayload.deserialize (protobuf.Reader data)

    if scan-request.msg == WiFiScanMsgType-TypeCmdScanStart:
      scan-start := scan-request.payload-cmd-scan-start
      period-per-channel-ms := scan-start.period-ms

      channels := ByteArray CHANNEL-NUM: it + 1
      ap-list_ = wifi.scan channels --period-per-channel-ms=period-per-channel-ms
      ap-list_.sort --in-place: | a b | compare-ap-by-rssi_ a b
      size := min ap-list_.size SCAN-AP-MAX
      ap-list_.resize size

      return WiFiScanPayload
          --msg=WiFiScanMsgType-TypeRespScanStart
          --status=Status-Success
          --payload-resp-scan-start=RespScanStart

    if scan-request.msg == WiFiScanMsgType-TypeCmdScanStatus:
      return WiFiScanPayload
          --msg=WiFiScanMsgType-TypeRespScanStart
          --status=Status-Success
          --payload-resp-scan-status=RespScanStatus
              --scan-finished=true
              --result-count=ap-list_.size

    if scan-request.msg == WiFiScanMsgType-TypeCmdScanResult:
      arg := scan-request.payload-cmd-scan-result
      scan-ap := ap-list_[arg.start-index .. arg.start-index + arg.count]

      ap-entries := scan-ap.map: |ap/wifi.AccessPoint|
        WiFiScanResult
          --ssid=ap.ssid.to-byte-array
          --channel=ap.channel
          --rssi=ap.rssi
          --bssid=ap.bssid
          --auth=ap.authmode

      return WiFiScanPayload
          --msg=WiFiScanMsgType-TypeRespScanResult
          --status=Status-Success
          --payload-resp-scan-result=RespScanResult
              --entries=ap-entries

    else:
      throw "Scan message is not supported"

