#!/bin/sh
#
# Create and restore symlinks based on /opt/.filetool.lst
#
# Copyright (c) 2016-2017 Alexander Williams, Unscramble <license@unscramble.jp>
#
# MIT License

set -u
set -e

RESTORE_DIR="$(cat /etc/sysconfig/mydata 2>/dev/null || echo mydata)"

OP="${1:-}"
DEVICE="${2:-}"

version(){
  echo "symlinktool v0.5.0"
  echo "Copyright (c) 2016-2017 Alexander Williams, Unscramble <license@unscramble.jp>"
  echo "License MIT"
}

usage(){
  version

  cat >&1 <<EOF

Backup and restore script based on values in /opt/.filetool.lst
An alternative to filetool.sh, which restores files as symlinks
https://github.com/aw/tinycore-symlinktool

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
EOF
}

check_root() {
  [ $(id -u) = 0 ] || { echo "must be root" ; exit 1; }
}

check_device() {
  [ ! -z "$DEVICE" ]  || { >&2 echo -e "\n\tNo device provided (ex: sda1)\n"; usage; exit 1; }
}

mount_device() {
  if ! grep -qw "/dev/${DEVICE} /mnt/${DEVICE}" /proc/mounts; then
    mkdir -p /mnt/${DEVICE} && \
    /bin/mount /dev/${DEVICE} /mnt/${DEVICE} >/tmp/symlinktool_mount.msg 2>&1 || return 1
  fi

  mkdir -p /mnt/${DEVICE}/${RESTORE_DIR} || return 1
}

create_symlinks() {
  /bin/tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst -cphf - 2>/tmp/symlinktool_tar.msg | /bin/tar -C /mnt/${DEVICE}/${RESTORE_DIR}/ -xvf - > /mnt/${DEVICE}/${RESTORE_DIR}.lst
  sync
}

restore_symlinks() {
  if [ -f "/mnt/${DEVICE}/${RESTORE_DIR}.lst" ]; then
    # create directories
    for directory in `cat /mnt/${DEVICE}/${RESTORE_DIR}.lst | grep "/$"`; do
      mkdir -p ${directory}
    done

    # create symlinks
    for target in `cat /mnt/${DEVICE}/${RESTORE_DIR}.lst | grep -v "/$"`; do
      if [ -e "/mnt/${DEVICE}/${RESTORE_DIR}/${target}" ]; then
        ln -snf /mnt/${DEVICE}/${RESTORE_DIR}/${target} $target
      fi
    done
  else
    # restore the original backup if there's no existing backup
    /usr/bin/filetool.sh -r "$DEVICE" >/tmp/symlinktool_original.msg 2>&1
  fi
}

undo_symlinks() {
  if [ -f "/mnt/${DEVICE}/${RESTORE_DIR}.lst" ]; then
    # undo symlinks
    for target in `cat /mnt/${DEVICE}/${RESTORE_DIR}.lst | grep -v "/$"`; do
      if [ -e "/mnt/${DEVICE}/${RESTORE_DIR}/${target}" ]; then
        rm -f $target
        mv -f /mnt/${DEVICE}/${RESTORE_DIR}/${target} $target
      fi
    done

    # remove final files/directories
    rm -rf /mnt/${DEVICE}/${RESTORE_DIR} /mnt/${DEVICE}/${RESTORE_DIR}.lst
    sync
  fi
}

save_symlinks() {
  cd /mnt/${DEVICE}/${RESTORE_DIR}
    if [ ! -d ".git" ]; then
      git init
      git config user.email "git@appliance.local"
      git config color.ui false
      echo "/var/log" > .gitignore
    fi

    # store the changes in git
    parent_cmd="$(/bin/ps -o comm -o pid | grep " $PPID$" | awk '{ print $1 }')"
    git add .
    git commit --no-gpg-sign -aqm "Saving backup files changes: $parent_cmd" || true
}

cd /

case "$OP" in
  -c|--create)
    check_root
    check_device
    echo -n "Creating backup up files in /mnt/${DEVICE}/${RESTORE_DIR}... "
    mount_device && \
    create_symlinks || exit 1
    [ -z `which git` ] || save_symlinks || exit 1
    echo -e "Done."
    ;;
  -r|--restore)
    check_root
    check_device
    echo -n "Restoring backup files from /mnt/${DEVICE}/${RESTORE_DIR}... "
    mount_device && \
    restore_symlinks || exit 1
    echo -e "Done."
    ;;
  -u|--undo)
    check_root
    check_device
    echo -n "Undoing changes and restoring files from /mnt/${DEVICE}/${RESTORE_DIR}... "
    mount_device && \
    undo_symlinks || exit 1
    echo -e "Done."
    ;;
  -h|--help)
    usage
    ;;
  -v|--version)
    version
    ;;
  *)
    usage
    ;;
esac
