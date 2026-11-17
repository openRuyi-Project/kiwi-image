set -x
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

mkdir -p /etc/dracut.conf.d
cat > /etc/dracut.conf.d/70-openruyi-installiso.conf <<EOF
hostonly="no"
hostonly_cmdline="no"
add_dracutmodules+="drm"
EOF

kernel-install add-all --verbose --entry-token=os-id
rm /etc/dracut.conf.d/70-openruyi-installiso.conf
sh -c "echo -e 'NAME=\"openRuyi\"\nPRETTY_NAME=\"openRuyi 26.11\"\nID=\"openruyi\"\nID_LIKE=\"openruyi\"\nLOGO=\"openRuyi\"\nVERSION_ID=\"26.11\"\nVERSION=\"26.11\"' > /etc/os-release"

# HACK: This is a workaround for Kiwi's overly clever modifications, which
# broke the correct behavior and forced the file to be moved
