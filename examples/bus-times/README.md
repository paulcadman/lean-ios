# bus-times

An iOS app that fetches live TfL bus arrival times over HTTP and renders them
with SDL. Demonstrates calling an Objective-C HTTP bridge from Lean.

## Build

```
make sim-app          # build for the iOS simulator
make run-sim-app      # build, boot a simulator, and launch the app
make -f Makefile.device device-app  # build for a physical device
```
