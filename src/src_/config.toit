// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import ble
import net.wifi
import protobuf

import .rpc
import .security
import ..proto_.constants-pb
import ..proto_.wifi-config-pb
import ..proto_.wifi-constants-pb

/**
An RPC service responsible for configuring the WiFi network.
*/
class WifiConfigRpcService extends ProtobufRpcService:
  static ID_ ::= 0x52
  static DESCRIPTION_ ::= "prov-config"

  ssid/string := ""
  password/string := ""
  network_/wifi.Client? := null
  done-callback_/Lambda

  constructor service/ble.LocalService --security/Security --done/Lambda:
    done-callback_ = done
    super service ID_ --description=DESCRIPTION_ --security=security

  close:
    critical-do:
      if network_ != null:
        network_.close
        network_ = null
      super

  handle-proto-request data/ByteArray -> protobuf.Message:
    wifi-config := WiFiConfigPayload.deserialize (protobuf.Reader data)

    if wifi-config.msg == WiFiConfigMsgType-TypeCmdSetConfig:
      arg := wifi-config.payload-cmd-set-config
      ssid = arg.ssid.to-string
      password = arg.passphrase.to-string

      return WiFiConfigPayload
          --msg=WiFiConfigMsgType-TypeRespSetConfig
          --payload-resp-set-config=RespSetConfig --status=Status-Success

    if wifi-config.msg == WiFiConfigMsgType-TypeCmdApplyConfig:
      network_ = wifi.open
          --ssid=ssid
          --password=password
          --save

      return WiFiConfigPayload
          --msg=WiFiConfigMsgType-TypeRespApplyConfig
          --payload-resp-apply-config=RespApplyConfig --status=Status-Success

    if wifi-config.msg == WiFiConfigMsgType-TypeCmdGetStatus:
      ap/wifi.AccessPoint ::= network_.access-point

      done-callback_.call
      return WiFiConfigPayload
          --msg=WiFiConfigMsgType-TypeRespGetStatus
          --payload-resp-get-status=RespGetStatus
              --status=Status-Success
              --state-connected=WifiConnectedState
                  --ip4-addr="$network_.address"
                  --auth-mode=ap.authmode
                  --ssid=ap.ssid.to-byte-array
                  --bssid=ap.bssid
                  --channel=ap.channel
    else:
      throw "WiFi config message is not supported"
