# Camera Import

A tiny macOS app that copies **only the new files** from a USB-connected camera into a folder you pick, and verifies every file afterwards.

Built because Apple's Image Capture kept stalling on large video files (over 4 GB) from a Nikon Z6. Camera Import uses [gphoto2](http://gphoto.org/) for the transfer, which handles big files properly.

## What it does

1. Asks which folder to import into (remembers the last one).
2. Quits Image Capture and frees the camera from macOS's camera service, so the transfer can take over.
3. Detects the camera and warns you if it's connected at slow USB 2.0 speed.
4. Compares the camera's files with the folder: anything missing, or an incomplete copy left over from a failed import, gets downloaded. Incomplete copies are moved to an `.incomplete` subfolder, never deleted.
5. Checks you have enough free disk space before starting.
6. Downloads the new files, then checks every file's size against the camera and tells you the result.

"New" means *not already in the folder you pick*. Choose an empty folder and it imports everything on the card.

## Install

Requires macOS and [Homebrew](https://brew.sh).

```bash
curl -fsSL https://raw.githubusercontent.com/roxproductions/camera-import/main/install.sh | bash
```

Or clone the repo and run `./install.sh`. This installs gphoto2 (via Homebrew) if needed and builds **Camera Import.app** in `~/Applications`. Drag it to your Dock for one-click imports.

The first time you open it, macOS asks whether Camera Import may control Terminal (that's where the progress is shown). Click **OK**.

## Use

1. Plug in the camera with a USB cable and switch it on.
2. Open **Camera Import** and pick the destination folder.
3. Watch the progress in the Terminal window. A notification tells you when it's done.

Run it again after any interruption: it picks up where it left off and re-downloads anything incomplete.

## Tips

- **Speed:** many USB-C cables are USB 2.0 only (~20–25 MB/s). A cable rated USB 3 / 5 Gbps, plugged straight into the Mac rather than through a hub, is much faster if your camera supports it.
- **Camera support:** works with any camera gphoto2 supports over USB (most Nikon, Canon, Sony, Fujifilm and others). Tested with a Nikon Z6.
- **Filename clashes:** files are matched by name. If your camera restarts its numbering (e.g. two `DSC_0001.JPG` in different card folders), the second one is treated as already imported.

## Uninstall

Delete `~/Applications/Camera Import.app` and `~/.camera-import-last-folder`. Remove gphoto2 with `brew uninstall gphoto2` if you don't need it.

## License

MIT
