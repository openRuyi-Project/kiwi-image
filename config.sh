set -x
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile
baseService sshd.service on
baseService sshd.socket off
# default use NetworkManager
baseService NetworkManager.service on
# for iso install, don't use systemd-boot
baseService systemd-boot-update.service off
# XXX: should adjust systemd file.
baseService systemd-homed.service off
baseService systemd-networkd-presistent-storage.service off
systemctl preset-all
