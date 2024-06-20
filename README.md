# Toit Provision

A Toit package to send WiFi credentials to ESP32 devices using BLE.

## Tool and App

The sending program can be either a CLI tool or mobile app.

### Cli Tool

The esp-idf comes with a BLE provisioning tool written in Python. It is
located in the `tools/esp_prov` directory.

Install the esp-idf as follows:
```
git clone --branch v5.0.1 --depth 1 https://github.com/espressif/esp-idf.git
cd esp-idf
./install.sh
. ./export.sh
```

You might also need to install the `protobuf` package. You can install it with `pip`:

```
pip install protobuf
```

Then run the following script. Replace `$SERVICE_NAME` with the service name of the device.

```
python3 tools/esp_prov/esp_prov.py --transport ble \
  --sec_ver 2 \
  --sec2_username wifiprov --sec2_pwd abcd1234 \
  --service_name $SERVICE_NAME
```

### Mobile Application

Download the mobile application from the following links:
* Android: [Play store](https://play.google.com/store/apps/details?id=com.espressif.provble)
* IOS: [App store](https://apps.apple.com/us/app/esp-ble-provisioning/id1473590141)
* [Github release page](https://github.com/espressif/esp-idf-provisioning-android/releases/).

## Example

The example `ble-provision.toit` shows how to integrate BLE provisioning on an
ESP32 module so its WiFi can be configured by the PC or Android app.

The example uses security 2 mode, which uses SRPa6 to exchange the session
key and AES-GCM to encrypt the session. The default username is `wifiprov` and
the default password is `abcd1234`. If you want to use different credentials,
run the following command to generate the `sec2_salt` and `sec2_verifier` in the
ESP-IDF directory:

```sh
python tools/esp_prov/esp_prov.py --transport ble \
    --sec_ver 2 --sec2_gen_cred \
    --sec2_username wifiprov --sec2_pwd abcd1234 \
```

Your users will need these credentials to provision the device.

### Installing with Jaguar

Installing with Jaguar is mainly for testing, as Jaguar is already set up with
WiFi credentials.

Install Jaguar as described in the [Jaguar README](https://github.com/toitlang/jaguar/blob/main/README.md).

Flash a new device by following the instructions in the README.

All further commands should be executed in the `examples` folder.
```sh
cd examples
```

Install the package dependencies:
```sh
jag pkg install
```

Then install the example as a new container:
```sh
jag container install -D jag.disabled -D jag.timeout=2m  provision ble_provision.toit
```

### With the Toit SDK

Download a Toit SDK from https://github.com/toitlang/toit/releases.
You will need the `toit-PLATFORM.tar.gz` and a matching firmware
envelope (`firmware-MODEL.gz`) from https://github.com/toitlang/envelopes.

Unzip the SDK and add the `toit/bin` and `toit/tools` folder to your path.

Unzip the firmware envelope. Make sure to *not* decompress the actual firmware archive file.
You can use `gunzip` to unzip the zipped file. You should end up with a single file and
not a folder.

All further commands should be executed in the `examples` folder.
```sh
cd examples
```

Install the package dependencies in the `examples` folder:

```sh
toit.pkg install
```

Compile the example. From the examples folder:

```sh
toit.compile -w ble_provision.snapshot ble_provision.toit
```

Add it to the firmware (where `$FIRMWARE_ENVELOPE` is the path to the firmware envelope):

```sh
firmware -e "$FIRMWARE_ENVELOPE" container install provision ble_provision.snapshot
```

Now you can flash the modified firmware to your ESP32 module.

```sh
firmware flash -e "$FIRMWARE_ENVELOPE" -p /dev/ttyUSB0
```
You might need to change the `/dev/ttyUSB0` to the correct port.
