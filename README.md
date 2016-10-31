# nRF5x-build-scripts

Makefiles used to compile nRF5x projects on Mac OS X (May work in Linux too).
Supports SDK 11.0.0 and 12.0.0/12.1.0 with softdevices included in the SDK.

## Setup

### Projects

All user configurable variables are located in the `Makefile.variables` file.
These have to be customized in order to achieve a working build environment.
Note, the template makefile(`Makefile.template`) is configured for projects with the following directory structure:
```
nRF5x project
  ├── Makefile
  ├── custom_linker_gcc_nrf_model.ld
  ├── src
  |     └── source files
  ├── include
        └── header files
```

### SDK

The `SDK_VERSIONS_PATH` should be the path to a folder containing the SDKs.
These directoried should be named correctly, i.e. SDK version number only.
```
SDK dir
  |
  ├── 11.0.0
  |     └── SDK content
  └── 12.1.0
        └── SDK content
```

### Flashing

To be able to flash controller using this build enviroment the path to nrfjprog must be set in `Makefile.variables`.
> nrfjprog is a part of *nRF5x-Command-Line-Tools* which is dependent on a working [J-Link Software](https://www.segger.com/downloads/jlink) installation.

## Usage

These makefiles are self explanatory. To get going do the following:
1. Copy `Makefile.template` to project root directory and set up the variables defined in it.
2. Run `make` or `make help` and observe the makefile reveal its secrets.

## SDK12 Note

Rename both .S files to lowercase .s in `components/toolchain/gcc/`.

## Compatibility

Currently supported SDKs and softdevices:

| SDK Version     | IC                 | Softdevices |
| --------------- | ------------------ | ----------- |
| 12.1.0 / 12.0.0 | nRF51x22, nRF52832 | S130, S132  |
| 11.0.0          | nRF51x22, nRF52832 | S130, S132  |
