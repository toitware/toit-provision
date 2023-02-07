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
also modify the newest version so it doesn't use the secure mode.
Follow the following steps to add the workaround for the BLE blocking issue.

1. clone esp-idf-provision-android

```sh
git clone --branch app-2.0.2 --depth 1 https://github.com/espressif/esp-idf-provision-android.git
```

2. modify code

Insert the following code in 594 line of `provision/src/main/java/com/espressif/provision/ESPDevice.java`:

```java
try {
    sleep(5000);
} catch (InterruptedException e) {
}
```

3. compile and run

You can use your own Android development kit to compile, install it on your mobile phone,
then use it to configure Wi-Fi access point for your ESP32.

## 2. Example

The example `ble_provision.toit` shows how to integrate BLE provisioning on an
ESP32 module so its WiFi can be configured by the PC or Android app.

### 2.1. Install Dependence
                                                                                                                                            
Install toit dependence packets in the `examples` folder:

```sh
cd examples
toit.pkg install
```

### 2.2 Compile and Download

Configure designated application by following steps in the root folder of toit:

```sh
cd toit
make menuconfig
```

The configuration is as following:

```sh
Component config  --->
    Toit  --->
        ($PATH/toit-provision/examples/ble_provision.toit) Entry point
```

* Note: Use real path to instead of $PATH

Run the following command to start to compile, download and flash the example:

```sh
make flash
```
