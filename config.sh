set -x
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile
baseService sshd.service on
baseService sshd.socket off
kernel-install add-all
