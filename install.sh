#!/usr/bin/env bash

directory_type=$(whiptail \
  --title "systemd failure handler installer" \
  --radiolist "Choose an installation directory:" 15 70 2 \
  "system" "for system units in /etc/systemd/system " OFF \
  "user" "for user units in ~/.config/systemd/user " ON \
  3>&1 1>&2 2>&3)

if [ $? != 0 ]; then
  exit $?
fi

case "$directory_type" in
  "system")
    directory="/etc/systemd/system"

    if [ "$(whoami)" != "root" ]; then
      echo "Script must be run as root for system installation."
      exit 1
    fi
    ;;
  "user")
    directory="$HOME/.config/systemd/user"
    ;;
esac


execstart=$(whiptail \
  --title "systemd failure handler installer" \
  --inputbox "Enter the command to run on a unit failure (use %i for the name of the failed unit):" 15 50 \
  3>&1 1>&2 2>&3)

if [ $? != 0 ]; then
  exit $?
fi

whiptail \
  --yesno "Install with the following options?\n\n\
Directory: $directory\n\
Command: $execstart" 15 50 \
  --defaultno \
  --yes-button "install" \
  --no-button "cancel"

if [ $? != 0 ]; then
  exit $?
fi

if [ ! -d "$directory" ]; then
  mkdir --parents "$directory"
fi


cat << EOF > "$directory/failure-handler@.service"
[Unit]
Description=Failure handler for %i
[Service]
Type=oneshot
# Perform some special action for when %i exits unexpectedly.
execstart=$execstart
EOF

if [ ! -d "$directory/service.d" ]; then
  mkdir --parents "$directory/service.d"
fi
cat << EOF > "$directory/service.d/00-failure-handler.conf"
[Unit]
OnFailure=failure-handler@%N.service
EOF

# Prevent recursive dependency chain
if [ ! -d "$directory/failure-handler@.service.d" ]; then
  mkdir --parents "$directory/failure-handler@.service.d"
fi

if [ ! -e "$directory/failure-handler@.service.d/00-failure-handler.conf" ]; then
  ln -s /dev/null "$directory/failure-handler@.service.d/00-failure-handler.conf"
fi

if [ "$(whoami)" = "root" ]; then
  systemctl --system daemon-reload
else
  systemctl --user daemon-reload
fi

cat << EOF > "/usr/local/bin/uninstall-systemd-failure-handler-$directory_type.sh"
#!/usr/bin/env bash
rm "$directory/failure-handler@.service" || exit 1
rm "$directory/service.d/00-failure-handler.conf" || exit 1
rm "$directory/failure-handler@.service.d/00-failure-handler.conf" || exit 1
[[ \$(ls -A "$directory/service.d") ]] || rmdir "$directory/service.d" || exit 1
[[ \$(ls -A "$directory/failure-handler@.service.d") ]] || rmdir "$directory/failure-handler@.service.d" || exit 1
rm "/usr/local/bin/uninstall-systemd-failure-handler-$directory_type.sh"
whiptail --msgbox "Uninstallation complete" 8 50
EOF

chmod u+x "/usr/local/bin/uninstall-systemd-failure-handler-$directory_type.sh"

whiptail --msgbox "Installation complete" 8 50
