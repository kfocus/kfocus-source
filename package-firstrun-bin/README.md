# Build Instructions

## Install Tools and Build

```bash
sudo apt install build-essential qt5-qmake qtdeclarative5-dev \
  qtbase5-dev qtquickcontrols2-5-dev debhelper-compat;

cd package-power-bin
mkdir build;
cd build;
qmake ..;
make
```

