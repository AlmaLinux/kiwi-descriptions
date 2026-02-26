# AlmaLinux OS 10 KIWI descriptions

This contains the image descriptions for building AlmaLinux OS 10 images
using [KIWI](https://osinside.github.io/kiwi/) as the image build tool.

## Image variants

Please look at [`VARIANTS`](VARIANTS.md) for details on the available
configurations that can be built.

## Image build quickstart

This is generally tested and expected to run on the latest release of AlmaLinux OS Kitten.
Other distributions may work, but there are no guarantees.

Set up your development environment and run the image build (substitute `<image_type>` and `<image_profile>` for the appropriate settings):

```bash
# Install epel
[]$ sudo dnf --assumeyes install epel-release
[]$ sudo crb enable
# Install kiwi
[]$ sudo dnf --assumeyes install kiwi kiwi-systemdeps distribution-gpg-keys
# Run the image build
[]$ sudo ./kiwi-build --kiwi-file=AlmaLinux-OS-Kitten.kiwi --image-type=<image_type> --image-profile=<image_profile> --output-dir ./outdir
```

## RISC-V (SiFive HiFive Premier P550)

A separate kiwi file is provided for building a disk image targeting the
[SiFive HiFive Premier P550](https://www.sifive.com/boards/hifive-premier-p550) board.

The image uses UEFI boot with GRUB2 on serial console, ext4 root filesystem,
and a 10 GB OEM disk layout. Packages are sourced from the AlmaLinux Kitten
RISC-V compose.

### Building natively on riscv64

```bash
[]$ sudo dnf --assumeyes install kiwi-cli distribution-gpg-keys
[]$ sudo kiwi-ng --type=oem --profile=PremierP550-Disk \
    --kiwi-file=AlmaLinux-OS-Kitten-P550.kiwi \
    system build --description ./ --target-dir /var/tmp/build
```

### Building in a container (cross-architecture)

```bash
[]$ podman run -d --platform=linux/riscv64 \
    --name almalinux-p550-build --privileged \
    -v $(pwd):/kiwi-descriptions:Z \
    quay.io/almalinuxorg/10-kitten-riscv64-development sleep infinity
[]$ podman exec almalinux-p550-build dnf install -y kiwi-cli distribution-gpg-keys
[]$ podman exec almalinux-p550-build kiwi-ng --type=oem --profile=PremierP550-Disk \
    --kiwi-file=AlmaLinux-OS-Kitten-P550.kiwi \
    system build --description /kiwi-descriptions --target-dir /var/tmp/build
```

The resulting raw disk image will be in `/var/tmp/build` and can be written to
an SD card or NVMe drive with `dd`.

## Licensing

These descriptions are licensed under the Apache Software License, version 2.0. See `LICENSE` for details.
