# Toit Provision

Provision ESP32 connect to designated Wi-Fi access point by PC or App of mobile phone.

## 1. Tool and App

A device that uses this library can be provisioned either from a PC or with an APP.

### 1.1 Tool

It is recommended to use the BLE provisioning tool that comes with the esp-idf v5.0.1.
Follow the following steps to obtain it:

1. clone esp-idf

```sh
git clone --branch v5.0.1 --depth 1 https://github.com/espressif/esp-idf.git
```

2. install tools

```sh
cd esp-idf
./install.sh
. ./export.sh
```

3. run script

Please use your own device's service name instead of `$SERVICE_NAME`

```
python3 tools/esp_prov/esp_prov.py --transport ble --sec_ver 2 --service_name $SERVICE_NAME --sec2_username wifiprov --sec2_pwd abcd1234
```

### 1.2 App

This package supports the secure mode 2 for BLE provisioning. As such,
we recommend to use newer version of the Android app which supports secure mode 2.
You can download the Android app from the official
[Play store](https://play.google.com/store/apps/details?id=com.espressif.provble) or
from the [Github release page](https://github.com/espressif/esp-idf-provisioning-android/releases/download/Provisioning_App_Release_2.1.0/ESP_BLE_Prov_2_1_0.apk).

## 2. Example

The example `ble_provision.toit` shows how to integrate BLE provisioning on an
ESP32 module so its WiFi can be configured by the PC or Android app.

- This example uses security 2 mode, which uses SRPa6 to exchange session
  key and AES-GCM to encrypt the session, you can use following command to generate
  the `sec2_salt` and `sec2_verifier`:

  ```sh
  cd esp-idf
  python tools/esp_prov/esp_prov.py --transport ble --sec_ver 2 --sec2_gen_cred --sec2_username wifiprov --sec2_pwd abcd1234
  ```
  You can also use your own `sec2_username` and `sec2_pwd`, as long as you provide these
  credentials when provisioning (for example in step 3 above).

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
When the device reboots it will automatically start the provisioning process.

### With the Toit SDK
Download a Toit SDK from https://github.com/toitlang/toit/releases.
You will need the `toit-PLATFORM.tar.gz` and a firmware envelope (`firmware-MODEL.gz`).

Unzip the SDK and add the `toit/bin` and `toit/tools` folder to your path.

Unzip the firmware envelope. Make sure to *not* decompress the actual firmware archive file.
You can use `gunzip` to unzip the zipped file. You should end up with a single file and
not a folder.

All further commands should be executed in the `examples` folder.
```sh
cd examples
```

#### Install Dependencies

Install the package dependencies in the `examples` folder:

```sh
toit.pkg install
```

#### Compile and Flash

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
