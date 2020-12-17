# COVID-19 DBCO App - iOS

## Introduction
This repository contains the iOS implementation of the Dutch COVID-19 DBCO app.

* The iOS app is located in the repository you are currently viewing.
* The Android app can be found here: https://github.com/minvws/nl-covid19-dbco-app-android
* The Backend repository can be found here: https://github.com/minvws/nl-covid19-dbco-app-backend
* Designs can be found here: https://github.com/minvws/nl-covid19-dbco-app-design
* Technical documentation can be found here: https://github.com/minvws/nl-covid19-dbco-app-coordination

## Local development setup
The project uses Cocoapods (1.10) as dependency manager.

A bootstrap.sh script is provided to setup required and optional dependencies for running this project. If you wish, you can also setup dependencies manually using bootstap.sh as a guide. 

The DBCO.workspace file should build out of the box for simulators. To run on a device ensure signing is setup properly: For the debug scheme you have to select a “Team” you are part of. If you are part of the Rijksoverheid developer team, add the desired device identifiers to the provisioning profiles.

In the Build Settings of the project, you can configure a couple of settings:
* `LOG_LEVEL` limits the log entries. Can be `none`, `error`, `warn`, `info` or `debug`. Sorted by increasing verbosity.
* `NETWORK_CONFIGURATION` determines to which api environment the app will connect. Can be `Development`, `Test`, `ACC` or `Production`
* `RESET_ENABLED` when set to `YES` will enable a debugging feature to clear all the data in the app and reset to the point before pairing. This feature is activated by tapping four times on the version label.
* `SHARE_LOGS_ENABLED` when set to `YES` allows the sharing of logs for debugging purposes. These logs also respect the `LOG_LEVEL`. This feature is activated by tapping four times on the version label.

## Development & Contribution process
The development team works on the repository in a private fork (for reasons of compliance with existing processes) and shares its work as often as possible.

If you plan to make non-trivial changes, we recommend to open an issue beforehand where we can discuss your planned changes.
This increases the chance that we might be able to use your contribution (or it avoids doing work if there are reasons why we wouldn't be able to use it).

Note that all commits should be signed using a gpg key.

