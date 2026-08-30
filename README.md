# frontmost

Prints what is in front on a jailbroken iOS device, as one line of JSON:

```
$ frontmost
{"bundleId":"com.purepoker.world.app","name":"Pure Poker","pid":770}
```

or `{}` when nothing is — the lock screen, the home screen, the app switcher.
The exit status is 0 in both cases; anything else is a failure to ask.

It exists for [rerake](https://github.com/regulad/rerake)'s `bookie-jb`, which
runs it over ssh to answer the device plane's "what app is in the foreground"
question on devices that have no automation harness to ask. Nothing about it
is specific to that: it is the one question, answered the one way every
"what is in front" tool on a jailbroken device has answered it —
`SBSCopyFrontmostApplicationDisplayIdentifier` from SpringBoardServices, with
the display name and pid from the same framework.

## Building

A [theos](https://theos.dev) tool. The package scheme is the one thing that
differs between rootful, rootless and RootHide, so it is overridable:

```sh
make package                                   # roothide, the default here
make package THEOS_PACKAGE_SCHEME=rootless
```

Installs to `/usr/bin/frontmost` as `xyz.regulad.frontmost`. Hosted on the
Sileo-style repository at `https://ios.regulad.xyz stable main`.

## Status

Written and packaged; not yet built against a device. If SpringBoard refuses
the query, the entitlement it asks for will be in its log, and the tool's
caller (`bookie-jb`) reports the absence as a named failure rather than
guessing at the foreground meanwhile.

## Licence

AGPL-3.0-or-later, like the service it was written for.
