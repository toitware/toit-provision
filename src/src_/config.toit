import net.wifi
import protobuf

import .ble show Process_
import .utils
import ..proto_.constants-pb
import ..proto_.wifi-config-pb
import ..proto_.wifi-constants-pb

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
          --save

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
