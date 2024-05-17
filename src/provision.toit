// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import monitor
import .src_.ble
import .src_.version
import .src_.session
import .src_.scan
import .src_.config
import .src_.ble as provision
import .src_.ble show Process_
import .src_.security

export SECURITY0 security2
export SERVICE-UUID

interface Security:
  encrypt data/ByteArray -> ByteArray
  decrypt data/ByteArray -> ByteArray
  handshake data/ByteArray -> ByteArray
  version -> int

class Provision:
  service_/BLEService_ := ?
  security_/Security := ?
  version-task_/Task? := null
  config-task_/Task? := null
  session-task_/Task? := null
  scan-task_/Task? := null
  latch_ := monitor.Latch

  constructor.ble service-name/string security/Security:
    return Provision.ble-with-uuid SERVICE-UUID service-name security

  constructor.ble-with-uuid service-uuid/ByteArray service-name/string .security_/Security:
    service_ = BLEService_ service-uuid service-name

  start -> none:
    if version-task_: throw "Already running"
    if latch_.has-value: throw "CLOSED"
    version-task_ = task:: ch-version-task_
    config-task_ = task:: ch-config-task_
    session-task_ = task:: ch-session-task_
    scan-task_ = task:: ch-scan-task_

    service_.start

  wait -> bool:
    return latch_.get

  static common-process_ security/Security process/Process_ characteristic/BLECharacteristic_:
    encrypt-data := characteristic.read
    characteristic.mutex-do:
      encrypted := characteristic.is-encrypted
      data := encrypted ? security.decrypt encrypt-data : encrypt-data
      resp := process.run data
      if resp.size > 0:
        data = encrypted ? security.encrypt resp : resp
        characteristic.write data

  ch-version-task_:
    characteristic := service_["proto-ver"]
    ver-process := VerProcess_ security_.version
    common-process_ security_ ver-process characteristic

  ch-session-task_:
    characteristic := service_["prov-session"]
    session-process := SessionProcess_ security_
    while true:
      common-process_ security_ session-process characteristic

  ch-scan-task_:
    characteristic := service_["prov-scan"]
    scan-process := ScanProcess_
    while true:
      common-process_ security_ scan-process characteristic

  ch-config-task_:
    characteristic := service_["prov-config"]
    config-process := ConfigProcess_
    while true:
      common-process_ security_ config-process characteristic
      if config-process.is-done:
        /**
        sleep for 1 seconds to wait for host tool or phone APP checking state and disconnecting
        */
        sleep --ms=1000
        latch_.set true
  /**
  Closes the provisioning and shuts down the service.
  */
  close:
    if version-task_:
      version-task_.cancel
      version-task_ = null
    if session-task_:
      session-task_.cancel
      session-task_ = null
    if scan-task_:
      scan-task_.cancel
      scan-task_ = null
    if config-task_:
      config-task_.cancel
      config-task_ = null

    service_.close

    if not latch_.has-value: latch_.set false


// TODO(florian): remove this function from here and use the one from the core libs.
get-mac-address -> ByteArray:
  #primitive.esp32.get-mac-address
