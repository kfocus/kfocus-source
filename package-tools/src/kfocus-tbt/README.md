## Build Instructions

```bash
# See debian/rules for build command. See debian/control for build requirements.

sudo apt install cmake debhelper-compat qtbase5-dev qtbase5-dev-tools;

mkdir -p kfocus-tbt/build
cmake -S kfocus-tbt/ -B kfocus-tbt/build/ -DCMAKE_BUILD_TYPE=RelWithDebInfo
cd kfocus-tbt/build
build
make
```

old: 442 x 404
tgt: 480 x 480


