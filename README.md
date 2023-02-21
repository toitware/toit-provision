# Toit Provision

Provision ESP32 connect to designated Wi-Fi access point by PC or App of mobile phone.

## 1. Tool and App

There is an issue with BLE provisioning of the used esp-idf. It only supports
blocking mode which causes the BLE protocol stack to block for about 4 seconds
without response for any outside requests. To work around this issue, modify
the provision source code of the PC and mobile applications. While the proposed
modifications are a bit hackish (and come with a 5 second delay) they are easy
and short.

### 1.1 Tool

It is recommended to use the BLE provisioning tool that comes with the esp-idf v5.0.
Follow the following steps to obtain and modify it:

1. clone esp-idf

```sh
git clone --branch v5.0 --depth 1 https://github.com/espressif/esp-idf.git
```

2. install tools

```sh
cd esp-idf
./install.sh
. ./export.sh
```

3. modify script

Insert the following code between lines 212 and 213 of `tools/esp_prov/esp_prov.py`

```python
time.sleep(5)
```

4. run script

Please use your own device's service name instead of `$SERVICE_NAME`

```
python3 tools/esp_prov/esp_prov.py --transport ble --sec_ver 0 --service_name $SERVICE_NAME
```

### 1.2 App

This package does not yet support the secure mode for BLE provisioning. As such,
we recommend to use an older version of the Android app. Alternatively, you can
also modify the newest version so it doesn't use the secure mode. For the same reasons,
only the QR-based provisioning is supported.

Follow the following steps to add the workaround for the BLE blocking issue.

1. clone esp-idf-provisioning-android

```sh
git clone --branch app-2.0.2 --depth 1 https://github.com/espressif/esp-idf-provisioning-android.git
```

2. modify code

Insert a sleep after the call to `processStartScanResponse`, by applying the following patch:

``` diff
diff --git a/provisioning/src/main/java/com/espressif/provisioning/ESPDevice.java b/provisioning/src/main/java/com/espressif/provisioning/ESPDevice.java
index 939e1e0..83dad54 100644
--- a/provisioning/src/main/java/com/espressif/provisioning/ESPDevice.java
+++ b/provisioning/src/main/java/com/espressif/provisioning/ESPDevice.java
@@ -592,6 +592,11 @@ public class ESPDevice {

                 processStartScanResponse(returnData);

+                try {
+                    sleep(5000);
+                } catch (InterruptedException e) {
+                }
+
                 byte[] getScanStatusCmd = MessengeHelper.prepareGetWiFiScanStatusMsg();
                 session.sendDataToDevice(ESPConstants.HANDLER_PROV_SCAN, getScanStatusCmd, new ResponseListener() {
```

3. compile and run

You can use your own Android development kit to compile, install it on your mobile phone,
then use it to configure Wi-Fi access point for your ESP32.

If you want to use a GitHub builder to compile the application, you can use the following workflow:
```yaml
name: Build
on:
  push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: ./gradlew build -x lint -x test
      - uses: actions/upload-artifact@v2
        with:
          name: apks
          path: app/build/outputs/apkg
```

## 2. Example

The example `ble_provision.toit` shows how to integrate BLE provisioning on an
ESP32 module so its WiFi can be configured by the PC or Android app.

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
