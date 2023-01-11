A systemd top level failure handler for all system or user units, as described in `systemd.unit(5)` `Example 3.`.


## Install

Run the installer with the following command:

```bash
curl -fsSL https://raw.githubusercontent.com/ioqy/systemd-failure-handler/master/install.sh | sudo sh
```

The installer lets you choose the installation directory (either system units or user units) and set the `ExecStart` command of the failure handler unit.

## Uninstall

For system units:

```bash
sudo /usr/local/bin/uninstall-systemd-failure-handler-system.sh
```

For user units:

```bash
/usr/local/bin/uninstall-systemd-failure-handler-user.sh
```
