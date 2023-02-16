// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

// The standard BLE provision demo for configuring Wi-Fi AP SSID and password

import encoding.hex
import provision

main:
  id := provision.get_mac_address[5..]
  service_name := "PROV_" + (hex.encode id)

  prov := provision.Provision.ble
      service_name
      provision.SECURITY0
  prov.start

  note ::= """
      Open the following URL in a browser:

      https://espressif.github.io/esp-jumpstart/qrcode.html?data=\
      {"ver":"v1","name":"$(service_name)","transport":"ble", "security":0}"""
  print note

  successful := prov.wait
  if successful:
    print "Provisioning is successful."

  prov.close
