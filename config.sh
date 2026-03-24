set -x
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile
baseService sshd.service on
baseService sshd.socket off
# default use NetworkManager
baseService NetworkManager.service on
# for iso install, don't use systemd-boot
# XXX: should adjust systemd file.
baseService systemd-homed.service off
baseService systemd-networkd-presistent-storage.service off
systemctl preset-all
baseService systemd-boot-update.service off
update-ca-trust
dnf reinstall dbus -y
if [[ "$kiwi_profiles" == "livecd" ]]; then
    echo "livecd"
    if [ -f /etc/sddm.conf ]; then
        echo -e '[Autologin]\nUser=openruyi\nSession=labwc\n' >> /etc/sddm.conf
    fi
    echo "WLR_NO_HARDWARE_CURSORS=1" >> /etc/environment
else
    echo "other, not use /etc/calamares and sddm autologin"
    rm -rf /etc/calamares
    rm -rf /etc/polkit-1/rules.d/00-installer.rules
    rm -rf /usr/local/share/applications/calamares.desktop
fi
