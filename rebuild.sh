#!/usr/bin/env bash

fvm flutter clean
fvm flutter packages pub run build_runner build --delete-conflicting-outputs
fvm flutter pub get