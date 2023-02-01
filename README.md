# Toit Provision

Provision ESP32 connect to designated Wi-Fi access point by PC or App of mobile phone.

## 1. Tool and App

There is an issue in BLE provision of esp-idf, it is that esp-idf only supports blocking mode which cause BLE protocol stack blocks for about 4 seconds without response for any outside request. To skip this issue, you should modify provision source code of PC and mobile APP. Please know that the supplied modification as following is the easiest method not the best method.

### 1.1 Tool

It is remanded to use esp-idf v5.0 BLE provision tool, operation steps are as following:

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

Because this toit BLE provision has not supported security mode, so it is remanded to use older version of android APP, if you know how to modify the APP source code to select non-encrypt mode, it will be better to use the newest version.
Following details just introduce how to skip BLE blocking issue.

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

You can use your own Android development kit to compile, install it to your mobile phone, then use it to configure Wi-Fi access point for your ESP32.

## 2. Example

This example `ble_provision.toit` shows how to provision ESP32 module connect to designated Wi-Fi access point by PC or App of mobile phone by BLE port.

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
