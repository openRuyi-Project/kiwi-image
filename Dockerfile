FROM ghcr.io/openruyi-project/creek:latest
RUN dnf update -y
RUN dnf install -y kiwi  kiwi-systemdeps-image-validation kiwi-systemdeps-filesystems kiwi-systemdeps-disk-images kiwi-systemdeps-iso-media glibc-gconv-modules-extra
RUN dnf install -y kiwi btrfs-progs xz git rpm-build systemd-container systemd-boot python-pefile xfsprogs

# 使用 kpartx 作为分区映射器（容器内无 lvm/dm 设备，需要用 kpartx 解析分区表）
RUN dnf install -y kpartx \
    && mkdir -p /etc \
    && printf 'mapper:\n  - part_mapper: kpartx\n' > /etc/kiwi.yml

WORKDIR /workspace
ENTRYPOINT ["kiwi-ng"]