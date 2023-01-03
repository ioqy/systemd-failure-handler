#!/bin/bash

DIRECTORY=$(whiptail \
  --title "systemd failure handler installer" \
  --radiolist "Choose an installation directory:" 15 60 4 \
  "/etc/systemd/system" "for system units" OFF \
  "~/.config/systemd/user" "for user units" ON \
  3>&1 1>&2 2>&3)

if [ $? != 0 ]; then
  exit $?
fi

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

if [ "$DIRECTORY" = "~/.config/systemd/user" ]; then
  DIRECTORY="$HOME/.config/systemd/user"
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
cat << EOF > "$DIRECTORY/service.d/10-all.conf"
[Unit]
OnFailure=failure-handler@%N.service
EOF

# Prevent recursive dependency chain
if [ ! -d "$DIRECTORY/failure-handler@.service.d" ]; then
  mkdir --parents "$DIRECTORY/failure-handler@.service.d"
fi

if [ ! -e "$DIRECTORY/failure-handler@.service.d/10-all.conf" ]; then
  ln -s /dev/null "$DIRECTORY/failure-handler@.service.d/10-all.conf"
fi

if [ "$(whoami)" = "root" ]; then
  systemctl --system daemon-reload
else
  systemctl --user daemon-reload
fi

whiptail --msgbox "Installation complete" 8 50
