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
# Enable CRB repository
#--------------------------------------
dnf config-manager --set-enabled crb

#======================================
# Set SELinux booleans
#--------------------------------------
## Fixes KDE Plasma, see rhbz#2058657
setsebool -P selinuxuser_execmod 1

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
if [[ "$kiwi_profiles" != *"Container"* ]] && [[ "$kiwi_profiles" != *"WSL"* ]]; then
	## Disable submenus to match Fedora
	echo "GRUB_DISABLE_SUBMENU=true" >> /etc/default/grub
	## Disable recovery entries to match Fedora
	echo "GRUB_DISABLE_RECOVERY=true" >> /etc/default/grub
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
fi

if [[ "$kiwi_profiles" == *"Cloud"* ]]; then
	## Enable tuned
	systemctl enable tuned.service

	## Enabled Xen Project PVHVM drivers only on x86_64
	## https://bugzilla.redhat.com/show_bug.cgi?id=1849082#c7
	if [[ "$(uname -m)" == "x86_64" ]]; then
		echo 'add_drivers+="xen-netfront xen-blkfront"' >> /etc/dracut.conf.d/xen_pvhvm.conf
		dracut -f --regenerate-all
	fi
fi

if [[ "$kiwi_profiles" == *"Azure"* ]]; then
	## Enable Azure service
	systemctl enable waagent.service
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
	## Enable oomd
	systemctl enable systemd-oomd.service
	## Enable resolved
	systemctl enable systemd-resolved.service
fi
## Enable persistent journal
mkdir -p /var/log/journal

#======================================
# Setup firstboot initial setup
#--------------------------------------

if [[ "$kiwi_profiles" == *"Disk"* ]]; then
	if [[ "$kiwi_profiles" != *"GNOME"* ]]; then
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
# Finalization steps
#--------------------------------------
# Inhibit the ldconfig cache generation unit, see rhbz2348669
touch -r "/usr" "/etc/.updated" "/var/.updated"

exit 0
