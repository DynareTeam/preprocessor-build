# Build system for Dynare's preprocessor

This project provides scripts to (cross)compile the Dynare's preprocessor for Linux (32bits/64bits), Windows (32bits/64bits) and OSX (32bits/64bits) targets from Linux. The code has been tested under Debian stable (stretch). To install the dependencies just type:

```shell
~# apt install < REQUIREMENTS
```

in the root of the project. To install the cross compilation tools for OSX target and the Boost headers, do:

```shell
~$ make install 
```

Then to produce the binaries:

```shell
~$ make -j
```
By default, the build system uses the last commit in the master branch of [dynare-preprocessor](https://github.com/DynareTeam/dynare-preprocessor.git). If the HEAD is 5727083865753f5abde8bdc0c20eee2b1ed5a501, then the build system will produce three `preprocessor.tar.gz` files under the `./builds/5727083865753f5abde8bdc0c20eee2b1ed5a501` folder with signed sha512sum:

```example
builds
├── 5727083865753f5abde8bdc0c20eee2b1ed5a501
│   ├── linux
│   │   ├── 32
│   │   │   ├── preprocessor.tar.gz
│   │   │   ├── sha256sum
│   │   │   └── sha256sum.asc
│   │   └── 64
│   │       ├── preprocessor.tar.gz
│   │       ├── sha256sum
│   │       └── sha256sum.asc
│   ├── osx
│   │   ├── 32
│   │   │   ├── preprocessor.tar.gz
│   │   │   ├── sha256sum
│   │   │   └── sha256sum.asc
│   │   └── 64
│   │       ├── preprocessor.tar.gz
│   │       ├── sha256sum
│   │       └── sha256sum.asc
│   └── windows
│       ├── 32
│       │   ├── preprocessor.tar.gz
│       │   ├── sha256sum
│       │   └── sha256sum.asc
│       └── 64
│           ├── preprocessor.tar.gz
│           ├── sha256sum
│           └── sha256sum.asc
└── c4ae840b207dbc4e61bff315e8eaa28fb742d9ea
    ├── linux
    │   ├── 32
    │   │   ├── preprocessor.tar.gz
    │   │   ├── sha256sum
    │   │   └── sha256sum.asc
    │   └── 64
    │       ├── preprocessor.tar.gz
    │       ├── sha256sum
    │       └── sha256sum.asc
    ├── osx
    │   ├── 32
    │   │   ├── preprocessor.tar.gz
    │   │   ├── sha256sum
    │   │   └── sha256sum.asc
    │   └── 64
    │       ├── preprocessor.tar.gz
    │       ├── sha256sum
    │       └── sha256sum.asc
    └── windows
        ├── 32
        │   ├── preprocessor.tar.gz
        │   ├── sha256sum
        │   └── sha256sum.asc
        └── 64
            ├── preprocessor.tar.gz
            ├── sha256sum
            └── sha256sum.asc
```
If one wants to build the preprocessor based on another commit or branch, he needs to provide the informations in a file called `configure.inc`. This file may look like:
```example
PREPROCESSOR_GIT_REMOTE=https://github.com/DynareTeam/dynare-preprocessor
PREPROCESSOR_GIT_BRANCH=master
PREPROCESSOR_GIT_COMMIT=03f88931c619e4352707d1bb4653d7db78983592
```
An example is provided in `configure.inc.sample` (just copy the file as `configure.inc` and adapt the content). The generated files can be pushed on a remote server if a file called `remote.inc` is available in the root directory (an example is provided in `remote.inc.sample`).
