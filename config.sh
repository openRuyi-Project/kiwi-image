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
elif [[ "$kiwi_profiles" == "livecd_kde" ]]; then
    echo "livecd_kde"
    if [ -f /etc/sddm.conf ]; then
        echo -e '[Autologin]\nUser=openruyi\nSession=plasmawayland\n' >> /etc/sddm.conf
    fi
    echo "KWIN_FORCE_SW_CURSOR=1" >> /etc/environment
    mkdir -p /home/openruyi/.config/
    chown openruyi:openruyi /home/openruyi/.config/
    cat > /home/openruyi/.config/plasma-localerc << EOF
[Formats]
LANG=en_US.UTF-8
LC_ADDRESS=zh_CN.UTF-8
LC_MEASUREMENT=zh_CN.UTF-8
LC_MONETARY=zh_CN.UTF-8
LC_NAME=zh_CN.UTF-8
LC_NUMERIC=zh_CN.UTF-8
LC_PAPER=zh_CN.UTF-8
LC_TELEPHONE=zh_CN.UTF-8
LC_TIME=zh_CN.UTF-8

[Translations]
LANGUAGE=zh_CN:en_US
EOF
    chown openruyi:openruyi /home/openruyi/.config/plasma-localerc
else
    echo "other, not use /etc/calamares and sddm autologin"
    rm -rf /etc/calamares
    rm -rf /etc/polkit-1/rules.d/00-installer.rules
    rm -rf /usr/local/share/applications/calamares.desktop
    mkdir -p /etc/repart.d
    cat > /etc/repart.d/50-root.conf <<EOF
[Partition]
Type=root
GrowFileSystem=yes
EOF
fi
