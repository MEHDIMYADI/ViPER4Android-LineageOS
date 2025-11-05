#!/system/bin/sh
# customize.sh

DYNLIB=true
MODPATH=${MODPATH:-$2}
APK_PATH="$MODPATH/common/apk/ViPER4Android.apk"

ui_print "- Setting up ViPER4Android-LineageOS..."

mkdir -p "$MODPATH/system/priv-app/ViPER4Android"
mkdir -p "$MODPATH/common/files"

REPLACE=""

set_permissions() {
  set_perm_recursive $MODPATH/system/priv-app/ViPER4Android 0 0 0755 0644
}

ui_print "- Extracting ViPER files..."
unzip -o "$ZIPFILE" 'common/apk/ViPER4Android.apk' -d $MODPATH >&2

if [ -f "$APK_PATH" ]; then
    mkdir -p "$MODPATH/system/priv-app/ViPER4Android"
    cp -f "$APK_PATH" "$MODPATH/system/priv-app/ViPER4Android/ViPER4Android.apk"
    ui_print "- APK installed successfully"
else
    ui_print "⚠ APK file not found!"
fi

ui_print "- Setting permissions..."
set_permissions

SKIPUNZIP=1
unzip -qjo "$ZIPFILE" 'common/functions.sh' -d $TMPDIR >&2
. $TMPDIR/functions.sh
