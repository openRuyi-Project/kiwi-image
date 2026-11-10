set -x
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

if [[ "$kiwi_profiles" == "installiso" ]]; then
    mkdir -p /etc/dracut.conf.d
    cat > /etc/dracut.conf.d/70-openruyi-installiso.conf <<EOF
hostonly="no"
hostonly_cmdline="no"
add_dracutmodules+="drm"
EOF
fi

kernel-install add-all --verbose --entry-token=os-id
if [[ "$kiwi_profiles" == "installiso" ]]; then
    rm /etc/dracut.conf.d/70-openruyi-installiso.conf
fi
# HACK: This is a workaround for Kiwi's overly clever modifications, which
# broke the correct behavior and forced the file to be moved
