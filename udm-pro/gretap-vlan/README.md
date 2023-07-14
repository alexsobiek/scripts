# UDM Pro VLANs over GRETAP
This script allows you to transport VLANs (or any other layer 2 traffic) to a remote location using a GRETAP interface.
This is useful if you have a set of VLANs which you want a remote location to have direct access to.

### Background
I created these because I have a few remote locations that I wanted to appear as physically one. By that I mean when you
plug in a device, whether it be directly to the UDM Pro or at the other end of the GRE tunnel, it gets an IP from UDM
Pro and appears to be on one large physical network. One of my specific use cases of this was for a summer cabin where
I'd like to have all of my WiFi networks & VLANs available to me, so all of my wireless devices just work and have 
a connection back to the others at home.


## Setup & Configuration
## Prerequisites
- You must be familiar with the [unifi-utilities/unifios-utilities](https://github.com/unifi-utilities/unifios-utilities)
project and have the "on-boot-script" installed. [More info here](https://github.com/unifi-utilities/unifios-utilities/blob/main/on-boot-script/README.md)
- Have [25-add-cron-jobs.sh](https://github.com/unifi-utilities/unifios-utilities/blob/main/on-boot-script/examples/udm-files/on_boot.d/25-add-cron-jobs.sh) in your `on_boot.d` folder

## Installation
The below steps assume you know where your data directory is. (It's either /mnt/data or /data)
1. Move `on_boot.d/50-gretap.sh` from this repository into your `on_boot.d` folder
2. Move `cronjobs/preserve-gretap` from this repository into your `cronjobs` folder

### Configuration
Your UDM Pro and remote router must have some sort of routable IPs between them. This can be over the public
internet, but GRE traffic is not encrypted so I highly discourage that. My setup used the builtin Wireguard server on
my UDM Pro, and my remote router as a client. 

#### Set variables
At the top of `50-gretap.sh` are a few variables which look like this:

```bash
# Define end points for tunnel
# This was tested using Wireguard, but should work over anything
LOCAL=172.30.0.1
REMOTE=172.30.0.201


# Define VLANs we want to tunnel
# 0 is default LAN
VLANS=(0 2)
```

These define the local and remote IPs of your two routers, and the VLANs you want to transport. VLAN ID 0 (which really
isn't a VLAN) is your LAN network. 

#### Remote Router
I have shared a portion of my working configuration for OpenWRT 
[here](https://github.com/alexsobiek/scripts/blob/main/gretap-vlan/openwrt/network). You should be able to do it on any 
linux box, however. You'll need 1 bridge interface per VLAN, and one GRETAP tunnel per bridge interface. 

### Finishing Up
Once you have everything configured, you can either reboot your UDM pro or run the `50-gretap.sh` script manually. If
you run it without rebooting, make sure to also run the `25-add-cron-jobs.sh` script as well.
