# Build Instructions

## Install Tools and Build

```bash
sudo apt install ... # get list of deps from package-firstrun-bin/debian/control

cd package-power-bin;
mkdir build;
cd build;
cmake ..;
make -j$(nproc);
```

