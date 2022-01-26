#!/bin/sh

# Usage:
# cd in to the rootfs directory
# sh ./break_chroot.sh
# You will be asked for your root password to unmount the mounts

# Get script path
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BACKUPPATH="$SCRIPTPATH/chroot/"

# Make the backup path
mkdir "$BACKUPPATH"

# Remove and unmount aarch64 mounts
echo "Unmounting aarch64 mounts"
sudo umount -R "$SCRIPTPATH/lib/ld-linux-aarch64.so.1"
sudo umount -R "$SCRIPTPATH/lib/aarch64-linux-gnu"

rmdir $SCRIPTPATH/lib/aarch64-linux-gnu
rm $SCRIPTPATH/lib/ld-linux-aarch64.so.1

# Unmount and delete mount points
echo "Unmounting container mounts"

sudo umount "$SCRIPTPATH/proc/"
sudo umount -R "$SCRIPTPATH/sys/"
sudo umount -R "$SCRIPTPATH/dev/pts/"
sudo umount -R "$SCRIPTPATH/dev/"

echo "Removing container mount folders"
rmdir "$SCRIPTPATH/sys"
rmdir "$SCRIPTPATH/dev/pts/"
rmdir "$SCRIPTPATH/dev"
rmdir "$SCRIPTPATH/proc"

# Move files from etc that we need to remove
echo "Backing up chroot files"
mkdir -p "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/hosts" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/resolv.conf" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/timezone" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/localtime" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/passwd" "$BACKUPPATH/etc/"

# Move various folders
mv "$SCRIPTPATH/boot" "$BACKUPPATH"
mv "$SCRIPTPATH/home" "$BACKUPPATH"
mv "$SCRIPTPATH/media" "$BACKUPPATH"
mv "$SCRIPTPATH/mnt" "$BACKUPPATH"
rsync -a "$SCRIPTPATH/root" "$BACKUPPATH"
rm -Rf "$SCRIPTPATH/root"
mv "$SCRIPTPATH/srv" "$BACKUPPATH"
mv "$SCRIPTPATH/tmp" "$BACKUPPATH"

# Only move opt if it is empty
[ "$(ls -A $SCRIPTPATH/opt)" ] && true || mv "$SCRIPTPATH/opt" "$BACKUPPATH"

# Copy over the apt folders
mkdir -p "$BACKUPPATH/var/cache/"
mkdir -p "$BACKUPPATH/var/lib/"

mv "$SCRIPTPATH/var/cache/apt" "$BACKUPPATH/var/cache/"
mv "$SCRIPTPATH/var/lib/apt" "$BACKUPPATH/var/lib/"

# If user was tinkering the the chroot then likely there are things that are set to root ownership
# Change ownership to fix this
echo "Fixing any potential permission issues"
sudo chown -R $USER:$GROUP "$SCRIPTPATH/"
