# Create and restore symlinks based on /opt/.filetool.lst

`symlinktool.sh` is designed to improve the [Persistence in TinyCore Linux](http://wiki.tinycorelinux.net/wiki:persistence_for_dummies#getting_tinycore_to_save_your_documents_and_settings) problem
by copying the files to a persistent disk, and then creating symlinks to those
files in place of the originals.

Example:

```
ls -lah /etc/shadow
lrwxrwxrwx 1 root root 37 Nov 11 08:30 /etc/shadow -> /mnt/sda1/mydata/etc/shadow
```

The **advantage** is you can now edit `persistent` files _without_ needing to back them up!
All changes will automatically be saved to `persistent` storage.

# Requirements

  * TinyCore Linux
  * Permanent disk storage (ex: /dev/sda1)
  * Ability to remaster TinyCore Linux

# Getting Started

  1. Run `./symlinktool.sh --create sda1` to backup your files to `/mnt/sda1`
  2. Edit the `/etc/init.d/tc-restore.sh` to replace `/usr/bin/filetool.sh` with `sudo /usr/bin/symlinktool.sh`
  3. Add `symlinktool.sh` to `/usr/bin`

Of course, you'll need a remastered `core.gz` or `corepure64.gz` which contains the edited `tc-restore.sh` and `symlinktool.sh`

# Usage

```
Usage: symlinktool.sh [option] <device>

Example:
  symlinktool.sh --create sda1

Options:
  (Note: options can not be combined)

  -c, --create   create a backup and store the files in <device>
  -r, --restore  restore symlinks pointing to backup files in <device>
  -u, --undo     undo changes and restore the backup files from <device>
  -h, --help     show this help message and exit
  -v, --version  show the application version and exit
```

# How it works

* Works similarly to `filetool.sh`, by reading include and exclude files from `/opt/.filetool.lst` and `/opt/.xfiletool.lst`, respectively
* Reads the `/etc/sysconfig/mydata` file which is based on the boot code `mydata`
* Reads the `$DEVICE` value obtained from `tc-restore.sh`
* Generates a `/mnt/$DEVICE/mydata.lst` file which contains the list of files which were backed up
* Doesn't create symlinks to directories, only files
* On boot, it replaces the original files and creates symlinks to the backed up files in `/mnt/sda1`

# Advanced

* If you don't want this change to be permanent, I suggest adding a boot code such as `restoresymlinks`, if found call `sudo /usr/bin/symlinktool.sh`, if not call `/usr/bin/filetool.sh`

# Status

This is currently in `alpha` status, so there may be some bugs (sorry!)

# License

[MIT License](LICENSE)

Copyright (c) 2016 Alexander Williams, Unscramble <license@unscramble.jp>
