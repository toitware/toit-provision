// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import ble
import net.wifi
import protobuf

import .rpc
import .security
import ..provision show WifiCredentials
import ..proto_.constants-pb
import ..proto_.wifi-config-pb
import ..proto_.wifi-constants-pb

/**
An RPC service responsible for configuring the WiFi network.
*/
class WifiConfigRpcService extends ProtobufRpcService:
  static ID_ ::= 0x52
  static DESCRIPTION_ ::= "prov-config"

  static FAIL-REASON-AUTH-ERROR_ ::= 0
  static FAIL-REASON-NETWORK-NOT-FOUND_ ::= 1

  ssid/string := ""
  password/string := ""
  network_/wifi.Client? := null
  was-successful_/bool := false
  fail-reason_/int? := null
  connecting-task_/Task? := null
  done-callback_/Lambda
  auto-save_/bool

  constructor service/ble.LocalService
      --security/Security
      --done/Lambda
      --auto-save/bool:
    done-callback_ = done
    auto-save_ = auto-save
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
      if connecting-task_:
        connecting-task_.cancel
      connecting-task_ = task::
        try:
          was-successful_ = false
          exception := catch:
            network_ = wifi.open
                --ssid=ssid
                --password=password
                --save=auto-save_
            was-successful_ = true
          fail-reason_ = "$exception".contains "not found"
              ? FAIL-REASON-NETWORK-NOT-FOUND_
              : FAIL-REASON-AUTH-ERROR_
        finally:
          connecting-task_ = null

      return WiFiConfigPayload
          --msg=WiFiConfigMsgType-TypeRespApplyConfig
          --payload-resp-apply-config=RespApplyConfig --status=Status-Success

    if wifi-config.msg == WiFiConfigMsgType-TypeCmdGetStatus:
      if was-successful_:
        ap/wifi.AccessPoint ::= network_.access-point

        // For simplicity invoke the done-callback before we have returned the
        // BLE response. The callback must make sure that the provisioning
        // process isn't immediately shut down.
        credentials := WifiCredentials --ssid=ssid --password=password
        done-callback_.call credentials

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

      else if connecting-task_:
        // Still trying to connect.
        return WiFiConfigPayload
            --msg=WiFiConfigMsgType-TypeRespGetStatus
            --payload-resp-get-status=RespGetStatus
                --status=Status-Success
                --sta-state=WifiStationState-Connecting

      else:
        // Connection failed.
        proto-reason := ?
        if fail-reason_ == FAIL-REASON-AUTH-ERROR_:
          proto-reason = WifiConnectFailedReason-AuthError
        else if fail-reason_ == FAIL-REASON-NETWORK-NOT-FOUND_:
          proto-reason = WifiConnectFailedReason-NetworkNotFound
        else:
          throw "Unknown fail reason"

        return WiFiConfigPayload
            --msg=WiFiConfigMsgType-TypeRespGetStatus
            --payload-resp-get-status=RespGetStatus
                --status=Status-Success
                --sta-state=WifiStationState-ConnectionFailed
                --state-fail-reason=proto-reason
    else:
      throw "WiFi config message is not supported"
