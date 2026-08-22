# Vogon iOS

SwiftUI iOS app for discovering, connecting to, and configuring Vogon environmental sensor devices over Bluetooth Low Energy (BLE).

## Features

- Automatic scanning for Vogon devices
- Connect / disconnect management with status feedback
- Reads characteristics from a dedicated configuration GATT Service
- Inline editing with type‐aware parsing
- Safe writes (only sends value if changed)

## GATT interface

Configuration Service UUID: `d0a823a6-fa98-4597-b0c1-d8577be0e158`

Characteristic groups

| Group                         | Field           | UUID   | Type   |
| ----------------------------- | --------------- | ------ | ------ |
| General                       | Read interval   | 0x0101 | UInt16 |
| Temperature & humidity sensor | Bulk size       | 0x0201 | UInt16 |
|                               | Bulk sleep      | 0x0202 | UInt16 |
| Particulate matter sensor     | Warm up time    | 0x0203 | UInt16 |
|                               | Bulk size       | 0x0204 | UInt16 |
|                               | Bulk sleep      | 0x0205 | UInt16 |
| Synchronization               | WiFi name       | 0x0701 | String |
|                               | WiFi password   | 0x0702 | String |
|                               | MQTT broker URL | 0x0703 | String |

## Build & run

1. Open `vogon.xcodeproj` in Xcode 16 (or current).
2. Ensure Bluetooth permission strings exist in `Info.plist`.
3. Select an iOS device (physical recommended for BLE) and run.

## Screenshots

|                                                                                                                                                                         |                                                                                                                                                       |
| :---------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------: |
|                       <img src="docs/screenshots/01-scanning.PNG" alt="Device scanning" width="420"><br>**Scanning:** Find nearby Vogon devices.                        |   <img src="docs/screenshots/02-device-home.PNG" alt="Device controls" width="420"><br>**Device controls:** Open settings, save changes, or reboot.   |
|       <img src="docs/screenshots/03-wifi-settings.PNG" alt="Wi-Fi and MQTT settings" width="420"><br>**Wi-Fi & Sync:** Set Wi-Fi credentials and the MQTT broker.       | <img src="docs/screenshots/04-advanced-settings.PNG" alt="Advanced settings categories" width="420"><br>**Advanced:** Choose a sensor settings group. |
| <img src="docs/screenshots/05-temp-and-rh-settings.PNG" alt="Temperature and humidity settings" width="420"><br>**Temperature & humidity:** Tune batch size and timing. |                                                                                                                                                       |
