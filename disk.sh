set -x
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

kernel-install add-all --verbose --entry-token=os-id
# HACK: This is a workaround for Kiwi's overly clever modifications, which
# broke the correct behavior and forced the file to be moved
