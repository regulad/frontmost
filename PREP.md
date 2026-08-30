# Preparation

What has to be true before `frontmost` answers, on the device and on the
machine that builds it.

## On the device

A jailbroken device on iOS 15 with a Procursus-based bootstrap — RootHide
(Dopamine 2) is what this is built and verified against — and the repository
the package is hosted on:

    https://ios.regulad.xyz stable main

Add it in Sileo (Sources → Edit → Add → `https://ios.regulad.xyz`), or from a
shell on the device:

```sh
echo 'deb https://ios.regulad.xyz stable main' > /etc/apt/sources.list.d/regulad.list
apt update
apt install xyz.regulad.frontmost
```

Then, with any app in front:

```sh
frontmost
```

prints that app as one line of JSON, and `{}` from the home screen. No root,
no sudo and no entitlement beyond the RootHide base set the package carries.
If the answer is `{}` with an app plainly in front, `frontmost --debug` says
which route answered and what BackBoard reported for each running app; on
iOS 15 SpringBoard's own route answers nobody, and that is expected.

`bookie-jb` runs it over ssh, as `mobile`, with `/usr/local/bin` on the
`PATH` it sets for every command — see rerake's `bookie-jb/docs/PREP.md`.

## On the machine that builds it

[theos](https://theos.dev) with the RootHide fork's package scheme, an iOS
SDK of 15.0 or newer under `$THEOS/sdks`, and `ldid`. Then:

```sh
make package FINALPACKAGE=1
```

produces `packages/xyz.regulad.frontmost_<version>_iphoneos-arm64e.deb`,
which is what goes to the repository. `THEOS_PACKAGE_SCHEME=rootless` on the
same command line builds for a rootless bootstrap instead.

To try a build on a device before it is hosted:

```sh
scp packages/xyz.regulad.frontmost_*.deb mobile@<device>:
ssh mobile@<device> sudo dpkg -i xyz.regulad.frontmost_*.deb
```

The package identifier is `xyz.regulad.frontmost` and the version is in
`control`; bump it there before a release build.
