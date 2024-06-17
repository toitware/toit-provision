// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import monitor
import .src_.ble
import .src_.security show SecurityCredentials

export SecurityCredentials

class Provision:
  ble_/BleProvision
  done-latch_/monitor.Latch

  constructor service-name/string --security-credentials/SecurityCredentials?=null:
    done-latch := monitor.Latch
    done-latch_ = done-latch
    ble_ = BleProvision
        --name=service-name
        --security-credentials=security-credentials
        --done=:: done-latch.set true

  start -> none:
    if done-latch_.has-value: throw "CLOSED"
    ble_.start

  wait -> bool:
    done-latch_.get
    // The latch is set as soon as the other side does the last action
    // (get result of the wifi-provisioning). At this point we haven't yet sent
    // the response back. So we need to wait a bit before closing the connection.
    sleep --ms=500
    return true  // Currently we only return if things are successful.

  /**
  Closes the provisioning and shuts down the service.
  */
  close:
    ble_.close
