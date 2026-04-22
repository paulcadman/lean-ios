# app

A minimal iOS app that calls a Lean function from Swift via a small C bridge.

## Build

```
make sim-app          # build for the iOS simulator
make run-sim-app      # build, boot a simulator, and launch the app
make -f Makefile.device device-app  # build for a physical device
```
