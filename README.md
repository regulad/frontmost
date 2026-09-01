# frontmost

Prints what is in front on a jailbroken iOS device, as one line of JSON:

```
$ frontmost
{"bundleId":"com.apple.mobilesafari","name":"Safari","pid":8817}
```

or `{}` when nothing is — the lock screen, the home screen, the app switcher.
The exit status is 0 in both cases; anything else is a failure to ask.

## How it answers

Two routes, tried in order:

1. **SpringBoard's own answer**, `SBSCopyFrontmostApplicationDisplayIdentifier`
   — what every tool of this kind used to call. On iOS 15.8 SpringBoard hands
   it to nobody this tool can be: NULL to root and mobile alike, with or
   without the launch/debug entitlements once thought to unlock it. It is
   tried first because it is cheap and may answer elsewhere; it is never
   trusted for anything else, since on the same device it answers the app's
   name with nothing and its pid with 1.
2. **BackBoard's view of every installed app.** `LSApplicationWorkspace`
   lists the apps, `BKSApplicationStateMonitor` reports each one's state, and
   exactly one carries the foreground-running bit. This needs no permission
   from SpringBoard and is the route that answers. Measured: Safari in front
   reads 8, everything else running reads 2, the home screen reads no 8.

The name comes from the same app record, and the pid from the kernel's
process list by matching an executable's path to the bundle.

`frontmost --debug` prints the same object with who asked, which route
answered, and what each route saw.

## Building

A [theos](https://theos.dev) tool, built the way geoshim's CLI is:

```sh
make package FINALPACKAGE=1                     # roothide, the default here
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

Installs to `/usr/local/bin/frontmost` as `xyz.regulad.frontmost`, signed
with the RootHide base entitlements (`entitlements.plist`) so it runs outside
a container. Hosted on the Sileo-style repository at
`https://ios.regulad.xyz stable main`; [PREP.md](PREP.md) is the device side
and the build side of getting it there.

## Status

Built and verified on an iPad mini 4, iOS 15.8.2, RootHide (Dopamine 2):
Safari in front reads Safari, the home screen reads `{}`, and `bookie-jb`'s
device read shows the same through the link.

## Licence

AGPL-3.0-or-later, like the service it was written for.
