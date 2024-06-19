// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import monitor
import .src_.ble
import .src_.security show SecurityCredentials

export SecurityCredentials

/**
WiFi credentials.
*/
class WifiCredentials:
  ssid/string
  password/string

  constructor --.ssid --.password:

  stringify -> string:
    return "SSID: $ssid, Password: $password"

/**
Used to provision the device with WiFi credentials using BLE.
*/
class Provision:
  ble_/BleProvision? := ?
  done-latch_/monitor.Latch

  /**
  Constructs a new provision object.

  The $name is published as the device name in the BLE advertisement.

  If $security-credentials is not provided, the device performs the provisioning
    without any encryption. If provided, the device uses the provided security
    credentials to encrypt the communication.

  If $auto-save is true, then the device saves the WiFi credentials to the flash
    memory after a successful provisioning.
  */
  constructor name/string
      --security-credentials/SecurityCredentials?=null
      --auto-save/bool=true:
    done-latch := monitor.Latch
    done-latch_ = done-latch
    ble_ = BleProvision
        --name=name
        --security-credentials=security-credentials
        --done=:: done-latch.set it
        --auto-save=auto-save

  /**
  Starts the provisioning process.

  The device advertises itself as a BLE peripheral and waits for a central device
    to connect and send the WiFi credentials.

  Use $wait to wait for the provisioning to finish.
  */
  start -> none:
    if not ble_: throw "CLOSED"
    if done-latch_.has-value: throw "DONE"
    ble_.start

  /**
  Returns the WiFi credentials after the provisioning is done.
  */
  wait -> WifiCredentials:
    result := done-latch_.get
    // The latch is set as soon as the other side does the last action
    // (get result of the wifi-provisioning). At this point we haven't yet sent
    // the response back. So we need to wait a bit before closing the connection.
    sleep --ms=500
    return result  // Currently we only return if things are successful.

  /**
  Closes the provisioning and shuts down the service.
  */
  close:
    ble_.close
    ble_ = null
