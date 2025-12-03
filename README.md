Plugins for some Apple-specific tasks, works on MacOS and iOS.

You can get a ready-to-use binary from the "releases" tab, just drag the contents 
into your addons directory.   You can start testing right away on a Mac project, 
and for iOS, export your iOS project and run.

The Makefile should produce a set of gdextensions that you can pick and choose.

* [GameCenter Integration Guide](Sources/GodotApplePlugins/GameCenter/GameCenterGuide.md)

The release contains both binaries for MacOS as dynamic libraries and
an iOS xcframework compiled with the "Mergeable Library" feature.
This means that for Debug builds, your Godot game contains a dynamic
library (about 10 megs at the time of this writing) that does not need
to be copied on every build speeding your development, but you can
switch to "Release Mode" and set "Create Merged Binary" to "Manual"
and you will further reduce the size of your executable (about 1.7
megs at the time of this writing.)

# After you download

Notice that MacOS will not let you load these dynamic libraries until you remove the 
quarantine attribute from them.

So you need to run this on the binaries after you unpack them:

```
xattr -dr com.apple.quarantine addons/GodotApplePlugins/bin/*framework
```

# Sizes

This compares the size of a Godot iOS export when you add this addon.

Plain Godot Export, empty:

```
Debug:   104 MB
Release:  93 MB
```

Godot Export, adding GodotApplePlugins with mergeable libraries:

```
Debug:   107 MB
Release:  95 MB
```

If you manually disable mergeable libraries and build your own addon:

```
Debug:   114 MB
Release: 105 MB
```
