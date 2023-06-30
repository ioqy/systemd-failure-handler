#!/bin/bash

DIRECTORY_TYPE=$(whiptail \
  --title "systemd failure handler installer" \
  --radiolist "Choose an installation directory:" 15 70 2 \
  "system" "for system units in /etc/systemd/system " OFF \
  "user" "for user units in ~/.config/systemd/user " ON \
  3>&1 1>&2 2>&3)

if [ $? != 0 ]; then
  exit $?
fi

case "$DIRECTORY_TYPE" in
  "system")
    DIRECTORY="/etc/systemd/system"

    if [ "$(whoami)" != "root" ]; then
      echo "Script must be run as root for system installation."
      exit 1
    fi
    ;;
  "user")
    DIRECTORY="$HOME/.config/systemd/user"
    ;;
esac


EXECSTART=$(whiptail \
  --title "systemd failure handler installer" \
  --inputbox "Enter the command to run on a unit failure (use %i for the name of the failed unit):" 15 50 \
  3>&1 1>&2 2>&3)

if [ $? != 0 ]; then
  exit $?
fi

whiptail \
  --yesno "Install with the following options?\n\n\
Directory: $DIRECTORY\n\
Command: $EXECSTART" 15 50 \
  --defaultno \
  --yes-button "install" \
  --no-button "cancel"

if [ $? != 0 ]; then
  exit $?
fi

if [ ! -d "$DIRECTORY" ]; then
  mkdir --parents "$DIRECTORY"
fi


cat << EOF > "$DIRECTORY/failure-handler@.service"
[Unit]
Description=Failure handler for %i
[Service]
Type=oneshot
# Perform some special action for when %i exits unexpectedly.
ExecStart=$EXECSTART
EOF

if [ ! -d "$DIRECTORY/service.d" ]; then
  mkdir --parents "$DIRECTORY/service.d"
fi
cat << EOF > "$DIRECTORY/service.d/00-failure-handler.conf"
[Unit]
OnFailure=failure-handler@%N.service
EOF

# Prevent recursive dependency chain
if [ ! -d "$DIRECTORY/failure-handler@.service.d" ]; then
  mkdir --parents "$DIRECTORY/failure-handler@.service.d"
fi

if [ ! -e "$DIRECTORY/failure-handler@.service.d/00-failure-handler.conf" ]; then
  ln -s /dev/null "$DIRECTORY/failure-handler@.service.d/00-failure-handler.conf"
fi

if [ "$(whoami)" = "root" ]; then
  systemctl --system daemon-reload
else
  systemctl --user daemon-reload
fi

cat << EOF > "/usr/local/bin/uninstall-systemd-failure-handler-$DIRECTORY_TYPE.sh"
#!/bin/bash
rm "$DIRECTORY/failure-handler@.service" || exit 1
rm "$DIRECTORY/service.d/00-failure-handler.conf" || exit 1
rm "$DIRECTORY/failure-handler@.service.d/00-failure-handler.conf" || exit 1
[[ \$(ls -A "$DIRECTORY/service.d") ]] || rmdir "$DIRECTORY/service.d" || exit 1
[[ \$(ls -A "$DIRECTORY/failure-handler@.service.d") ]] || rmdir "$DIRECTORY/failure-handler@.service.d" || exit 1
rm "/usr/local/bin/uninstall-systemd-failure-handler-$DIRECTORY_TYPE.sh"
whiptail --msgbox "Uninstallation complete" 8 50
EOF

chmod u+x "/usr/local/bin/uninstall-systemd-failure-handler-$DIRECTORY_TYPE.sh"

whiptail --msgbox "Installation complete" 8 50
