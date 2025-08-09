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

## Licensing

These descriptions are licensed under the Apache Software License, version 2.0. See `LICENSE` for details.
