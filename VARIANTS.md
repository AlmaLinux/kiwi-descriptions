## Image variants

### For the `AlmaLinux-OS-Kitten.kiwi` and `AlmaLinux-OS.kiwi` kiwi files

| Name                           | Image type | Image profiles                        |
|--------------------------------|------------|---------------------------------------|
| Minimal Base image             | `oem`      | `Minimal-Disk`                        |
| Base Cloud image               | `oem`      | `Cloud-Base-Generic`                  |
|                                |            | `Cloud-Base-AmazonEC2`                |
|                                |            | `Cloud-Base-Azure`                    |
|                                |            | `Cloud-Base-GCE`                      |
| Base Container                 | `oci`      | `Container-Base-Generic-Init`         |
|                                |            | `Container-Base-Generic-Minimal`      |
|                                |            | `Container-Base-Generic`              |
| Toolbox Container              | `oci`      | `Container-Toolbox`                   |
| Base Vagrant image             | `oem`      | `Vagrant-Base-libvirt`                |
|                                |            | `Vagrant-Base-VirtualBox`             |
| KDE Plasma Desktop images      | `iso`      | `KDE-Desktop-Live`                    |
|                                | `oem`      | `KDE-Desktop-BtrfsDisk`               |
|                                | `oem`      | `KDE-Desktop-XFSDisk`                 |
| GNOME Desktop images           | `iso`      | `GNOME-Live`                          |
|                                | `oem`      | `GNOME-BtrfsDisk`                     |
|                                | `oem`      | `GNOME-XFSDisk`                       |
