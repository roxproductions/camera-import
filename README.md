# Camera Import

A tiny macOS app that copies **only the new files** from a USB-connected camera into a folder you pick, and verifies every file afterwards.

Built because Apple's Image Capture kept stalling on large video files (over 4 GB) from a Nikon Z6. Camera Import uses [gphoto2](http://gphoto.org/) for the transfer, which handles big files properly.

## Why you might want this

If you've ever plugged a camera into a Mac to grab your footage, you've probably run into at least one of these:

- **Image Capture stalls on big video files.** Cameras talk to computers over USB using a protocol (PTP) that was designed with a 4 GB per-file limit. Modern cameras happily record 5, 7 or 10 GB clips, and macOS's built-in import tools often hang on them forever with a 0-byte file and no error.
- **Re-importing everything, or picking files by hand.** The card fills up over several shoots. Image Capture and Photos don't reliably tell you which files you already copied to *your* project folder, so you either drag everything again and end up with duplicates like `DSC_1234 1.MOV`, or scroll through hundreds of thumbnails selecting the new ones.
- **Silent failures.** A loose cable, a sleeping camera or a full disk can leave you with truncated or empty files that look fine in Finder until you open them in your editor.
- **No card reader.** The usual advice is "just buy a card reader". For XQD and CFexpress cards that's an extra piece of kit, when the camera and its cable should be enough.

Camera Import fixes those in one click: it pulls only what's missing from the folder you choose, copes with files over 4 GB, refuses to start when there isn't enough space, and checks every file against the camera at the end so you know the import is complete before you format the card.

It's handy for videographers and photographers who offload straight from the camera: shooting days, events, vlogs, or anyone tired of babysitting Image Capture.

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
