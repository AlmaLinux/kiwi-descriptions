#!/bin/bash

set -euxo pipefail

#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]-[$kiwi_profiles]..."

#======================================
# Set SELinux booleans
#--------------------------------------
## Fixes KDE Plasma, see rhbz#2058657
setsebool -P selinuxuser_execmod 1

#======================================
# Fix system defaults
#--------------------------------------
echo UTC >> /etc/adjtime
sed -i '/^KEYMAP=/a FONT="eurlatgr"' /etc/vconsole.conf

#======================================
# Clear machine specific configuration
#--------------------------------------
## Clear machine-id on pre generated images
rm -f /etc/machine-id
echo 'uninitialized' > /etc/machine-id
## remove random seed, the newly installed instance should make its own
rm -f /var/lib/systemd/random-seed

#======================================
# Configure grub correctly
#--------------------------------------
installarch=$(uname -m)
if [[ "$kiwi_profiles" != *"Container"* ]] && [[ "$kiwi_profiles" != *"WSL"* ]] && [[ "$installarch" != "s390x" ]]; then
	## Set distributor name for GRUB menu entries
	echo 'GRUB_DISTRIBUTOR="$(sed '"'"'s, release .*$,,g'"'"' /etc/system-release)"' >> /etc/default/grub
	## Disable submenus to match Fedora
	echo "GRUB_DISABLE_SUBMENU=true" >> /etc/default/grub
	## Disable recovery entries to match Fedora
	echo "GRUB_DISABLE_RECOVERY=true" >> /etc/default/grub
	## Enable BLS (Boot Loader Specification) support
	echo "GRUB_ENABLE_BLSCFG=true" >> /etc/default/grub
	## On EL8 UEFI the grub2-efi package creates /boot/grub2/grubenv as a
	## symlink to the EFI partition. With a separate boot partition GRUB
	## cannot follow cross-partition symlinks, causing a harmless but ugly
	## "file `/grub2/grubenv' not found" error. Replace with a real file.
	if [ -L /boot/grub2/grubenv ] && [ "$(rpm -E %rhel)" = "8" ]; then
		rm /boot/grub2/grubenv
		grub2-editenv /boot/grub2/grubenv create
	fi
	## Write `menu_auto_hide=1` into grubenv to match Fedora anaconda installs
	## Set boot_success to avoid displaying the grub menu on first boot
	grub2-editenv /boot/grub2/grubenv set menu_auto_hide=1 boot_success=1
fi

#======================================
# Resize root partition on first boot
#--------------------------------------

if [[ "$kiwi_profiles" == *"Disk"* ]]; then
	mkdir -p /etc/repart.d/
	cat > /etc/repart.d/50-root.conf << EOF
[Partition]
Type=root
EOF
fi

#======================================
# Delete & lock the root user password
#--------------------------------------
if [[ "$kiwi_profiles" == *"Cloud"* ]] || [[ "$kiwi_profiles" == *"WSL"* ]]; then
	passwd -d root
	passwd -l root
fi

#======================================
# Setup default services
#--------------------------------------

if [[ "$kiwi_profiles" == *"Cloud"* ]] || [[ "$kiwi_profiles" == *"WSL"* ]]; then
	## Enable cloud-init
	systemctl enable cloud-config.service cloud-final.service cloud-init.service cloud-init-local.service cloud-init.target
	## Set cloud-init default user to almalinux
	sed -i 's/^\(\s\+name:\).*$/\1 almalinux/' /etc/cloud/cloud.cfg
fi

if [[ "$kiwi_profiles" == *"Azure"* ]]; then
	## Enable Azure service
	systemctl enable waagent.service
fi

if [[ "$kiwi_profiles" == *"Generic"* ]]; then
	## Enable tuned with virtual-guest profile
	systemctl enable tuned.service
	echo virtual-guest > /etc/tuned/active_profile
	echo "" > /etc/tuned/profile_mode
	## Use full kernel package as default for future updates
	sed -i 's/^DEFAULTKERNEL=.*/DEFAULTKERNEL=kernel/' /etc/sysconfig/kernel
fi

if [[ "$kiwi_profiles" == *"Live"* ]]; then
	## Enable livesys services
	systemctl enable livesys.service livesys-late.service
	if [[ "$kiwi_profiles" == *"GNOME"* ]]; then
		echo 'livesys_session="gnome"' > /etc/sysconfig/livesys
	fi
	if [[ "$kiwi_profiles" == *"KDE"* ]]; then
		echo 'livesys_session="kde"' > /etc/sysconfig/livesys
	fi
fi

if [[ "$kiwi_profiles" != *"Container"* ]] && [[ "$kiwi_profiles" != *"WSL"* ]]; then
	## Enable chrony
	systemctl enable chronyd.service
	## Enable oomd and resolved (not installed in cloud images)
	if [[ "$kiwi_profiles" != *"Cloud"* ]]; then
		systemctl enable systemd-oomd.service
		systemctl enable systemd-resolved.service
	fi
fi
## Enable persistent journal
mkdir -p /var/log/journal

#======================================
# Setup firstboot initial setup
#--------------------------------------

installarch=$(uname -m)
if [[ "$kiwi_profiles" == *"Disk"* ]]; then
	if [[ "$kiwi_profiles" != *"GNOME"* ]] && [[ "$installarch" != "riscv64" ]]; then
		## Enable initial-setup
		systemctl enable initial-setup.service
		## Enable reconfig mode
		touch /etc/reconfigSys
	fi
fi

#======================================
# Setup default target
#--------------------------------------
if [[ "$kiwi_profiles" == *"Live"* ]]; then
	systemctl set-default graphical.target
else
	systemctl set-default multi-user.target
fi

#======================================
# Remove Xen dracut config on non-x86_64 or non-Cloud
#--------------------------------------
installarch=$(uname -m)
if [[ "$kiwi_profiles" != *"Cloud"* ]] || [[ "$installarch" != "x86_64" ]]; then
	rm -f /etc/dracut.conf.d/xen_pvhvm.conf
fi

#======================================
# Cloud image cleanup
#--------------------------------------
if [[ "$kiwi_profiles" == *"Cloud"* ]]; then
	truncate -s 0 /etc/resolv.conf
	rm -f /var/lib/systemd/credential.secret
	dnf clean all
	rm -f /var/lib/dnf/history*
fi

#======================================
# Finalization steps
#--------------------------------------
# Inhibit the ldconfig cache generation unit, see rhbz2348669
touch -r "/usr" "/etc/.updated" "/var/.updated"

exit 0
