# Luadns-DDNS

DDNS Client implemented as a Simple Bash Script that uses the [Luadns.com](https://luadns.com)
[REST API](https://www.luadns.com/api.html), with email notifications.

Useful if you already have a domain hosted at [Luadns.com](https://luadns.com) and want to add single or multiple dynamic records.

A custom notification hook is also supported - an example is provided below for [ntfy](https://ntfy.sh).

# Table of Contents

- [Introduction](#introduction)    
  - [Usage](#usage)    
- [Installation](#installation)
  - [Package Installation - Debian Based Distros](#package-installation---debian-based-distros)
  - [Manual Installation - Other Distros](#manual-installation---other-distros)
  - [Installation on IPFire](#installation-on-ipfire)
- [Getting Started](#getting-started)     
  - [Step 1 - Up-Front Requirements](#step-1---up-front-requirements)     
  - [Step 2 - Config File Setup](#step-2---config-file-setup)    
  - [Step 3 - Setting Up Email Notifications](#step-3---setting-up-email-notifications)
    - [Email Notifications on IPFire](#email-notifications-on-ipfire)
    - [Custom Notification Hook - ntfy](#custom-notification-hook---ntfy)
  - [Step 4 - Call the Script Directly](#step-4---call-the-script-directly)    
  - [Step 5 - Automation with Systemd](#step-5---automation-with-systemd)
  - [Step 5 for IPFire - Cron Setup](#step-5-for-ipfire---cron-setup)
- [Further Examples](#further-examples)    
- [Issues](#issues)

# Introduction

Thank you for your interest in this script. The author has been using this for quite a while
now with great success, so hopefully it can prove useful to someone else also.

This is a DDNS client for domains hosted at **Luadns.com** implemented as a simple bash script that tracks the
Public IP using 3 possible methods:

1. Directly looking at the IP of a Local Network Interface - Useful for Systems that already have Public IPs like Firewalls.     
2. Using a number of publically available websites that output the IP in plain text like [icanhazip.com](https://icanhazip.com) or [ifconfig.co](https://ifconfig.co)    
3. Using a DNS Request. Certain well known DNS providers like **Cloudflare** or **Google** have DNS records than when queried return the IP of the sender. This can be much quicker than HTTP/HTTPs requests.

It keeps track of the Public IP it receives from whichever of the above methods and monitors it for changes. If changes are detected, it will update a corresponding DNS Record or multiple DNS
Records at **Luadns.com** using their REST API Server.

It is intended to be ran as a scheduled task via systemd or cron job. The default implementation (if installed by the package) is to run every 5 minutes.

The **Luadns.com** DNS Nameservers are then queried for the updated DNS Record or Records to make sure the update was successful. If an error is encountered or the records fail to update,
the script will then automatically try to update the DNS records at the next interval it is ran even if it does not detect a change in the Public IP address. This gives the best possible chance that
the DNS records one is using for DDNS are reliably updated.

It will notify the user of an IP Change via email or through the use of a custom notification hook (if configured). The user is also notified the very 1st time the Script
is ran. Emails are sent using **mutt**. Sample email configurations are shown below.

An optional custom notification hook is also supported to allow the user to use an alternative form of notification in addition to or instead of the standard emails if desired (see below).

The script will also update the DNS Record or Records at **Luadns.com** at certain times regardless of whether a change in the Public IP is detected or not. This ensures the DNS Record is kept up to date
at all times regardless of the circumstances.

Updating multiple records is also supported. This is to handle the situation whereby multiple records point to the same IP address which is dynamic and can change. 

Usually in this situation one would get a DDNS client to update a single record, and change all of the other records to CNAMEs to point to the former record.

This works but CNAME records increase the amount of queries. Furthermore, some services like **XMPP** can require one set up A records and do not recommend one use CNAMEs. The script presents an alternative
to this by supporting the update of multiple records at once. However it is assumed that if multiple records are being used, all are part of the same DNS **Zone**, that is they are of the
following shape:

* record-to-update1.mydomain.org    
* record-to-update2.mydomain.org    
* record-to-update3.mydomain.org    

If multiple records are specified and they are **NOT** part of the same DNS **Zone**, the script will exit with an error. If it is desired to update records on multiple DNS **Zones**, then it
is best create a different config file and use **-c** option as specified below.

Luadns.com do mention using ddclient on their documentation (see below link), but since the author created a [Hook Script](https://github.com/zoot101/dehydrated-hook-luadns) for **dehydrated**
for use with **Luadns.com**, it was a natural progression to create this DDNS update script. 

* [https://www.luadns.com/dyndns.html](https://www.luadns.com/dyndns.html)

Note that the script only supports Type A DNS Records (IPv4 Addressing Only), IPv6 (AAAA) is not supported.

# Usage

```bash
Usage: luadns-ddns            [OPTIONS...]

  -f, --force                 Force an update of the record regardless of time or
                              whether an IP Change is detected
  -c, --config                Override the default config file. Could be useful to
                              update multiple records
  -i, --info                  Querys the Luadns REST API Endpoints for the user details,
                              zones, zone records and exits. Allows testing the login
                              credentials and inspecting the Zone/Records.
  -h, --help                  Print help

The script can also be called with no options like so:

 $ luadns-ddns
```

# Installation

Two methods are available for installation - via the Debian package or manually.

A package is provided for Debian and its derivatives. The author has tested this on Debian Bullseye (11), Debian Bookworm (12), and Debian Trixie (13), Fedora 42 and
IPFire (2.29 - Core 195).

## Package Installation - Debian Based Distros

To install the package (for Debian based distros), download it from the releases
page [HERE](https://github.com/zoot101/luadns-ddns/releases) and do the following.

Note that it's better to use **apt** rather than **dpkg** so the dependencies will be automatically installed.

```bash
sudo apt install ./luadns-ddns_2.0.0-1_amd64.deb
```
During the package installation, the user is prompted to select a user other than root to run the script if desired.

Then proceed to the **Getting Started** section below.

## Manual Installation - Other Distros

First download the latest source code archive from the releases page [HERE](https://github.com/zoot101/luadns-ddns/releases).
and extract it, then do the below: 

```bash
unzip luadns-ddns-2.0.0.zip      # For the Zip File
tar xvf luadns-ddns-2.0.0.zip    # For the Tar File

cd luadns-ddns

# Install the Main Script
chmod +x luadns-ddns
sudo cp luadns-ddns /usr/bin/

# Create script working directory
sudo mkdir /var/lib/luadns-ddns

# Install the Manual Entry (Optional)
sudo cp ./manual/luadns-ddns.1.gz /usr/share/man/man1/

# Install the default config file
sudo cp ./config/luadns-ddns.conf /etc/

# Install the Systemd Unit Files
sudo cp luadns-ddns.service /etc/systemd/system
sudo cp luadns-ddns.timer /etc/systemd/system

# If one wants to run the service as a user other
# than root, generate a drop-in file like so:
mkdir /etc/systemd/system/luadns-ddns.service.d/
echo "[Service]" > /etc/systemd/system/luadns-ddns.service.d/user.conf
echo "User=your_username" >> /etc/systemd/system/luadns-ddns.service.d/user.conf
echo "Group=your_groupname" >> /etc/systemd/system/luadns-ddns.service.d/user.conf

# Update permissions on the working directory
# if using a non-root user
chown your_username:your_groupname /var/lib/luadns-ddns/

# Reload systemd
sudo systemctl daemon-reload
```

Next ensure all dependencies are installed:

* curl, jq, awk, dig
* mutt

If on Debian, one can do the below.

```bash
# For Debian (or its derivatives)
sudo apt install bind9-dnsutils bash coreutils gawk mutt curl jq

# For Fedora
sudo dnf install bind-utils bash coreutils gawk mutt curl jq 
```

## Installation on IPFire

If one is using [IPFire](https://www.ipfire.org) as their Firewall (it comes highly recommended from
the author), it is easy to get the script up and running, but the steps are
a bit different (see below):

```bash
unzip luadns-ddns-2.0.0.zip       # For the Zip File
tar xvf luadns-ddns-2.0.0.tar.gz  # For the Tar File

cd luadns-ddns

# Install the Main Script
chmod +x luadns-ddns
cp luadns-ddns /usr/bin/

# Install the Config File
cp ./config/luadns-ddns.conf /etc/

# Create the working directory for the script
mkdir /var/lib/luadns-ddns

# Next if you want the script to run as a user other
# than root create a new user like so:
useradd -U -d /home/user1 -s /bin/bash -c "non root user" user1

# Update permissions on the script working directory
chown -R user1:user1 /var/lib/luadns-ddns
```
All of the dependencies (curl, awk, jq etc.) are included in the default
installation of [IPFire](https://www.ipfire.org).

One can run the script as **root** on IPFire, but the author doesn't recommend it
as the crontab for **root** is prone to getting changed upon subsequent
updates to **IPFire**, to avoid this running as an alternative user to root is
necessary.

Note that for IPFire, **mutt** is not provided in the repos, but a sample
notification hook script is provided here and one can use to send emails here:
(See the section on Email Notifications below)

- [https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/send-email-ipfire.sh](https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/send-email-ipfire.sh)

Then proceed to the **Getting Started** section below.

# Getting Started

A guide to getting started with the script is shown below:

## Step 1 - Up-Front Requirements

To use this script the following is requried up front to being using it.

* Ownership of a valid domain name    
* Luadns servers (ns[1-4].luadns.net) configured for the Domain at your Domain Registrar   
* API access enabled in the Luadns.com account settings    
* A valid API Key created for the zone in question (record.example.org: example.org is the zone)    
* A Type DNS Records (IPv4) created at Luadns.com for use with the script    

The finer details about the above are not considered here and left up to the user.

## Step 2 - Config File Setup

The next thing that is required is to configure the config file for the script.

A description of what is required in the config file is shown here. A sample config file can be found here:    

- [https://github.com/zoot101/luadns-ddns/blob/main/config/luadns-ddns.conf](https://github.com/zoot101/luadns-ddns/blob/main/config/luadns-ddns.conf)

The config file should be specified in one of the following 3 ways:

1. Via the -c, \--config option - Example: **$ luadns-ddns -c /path/to/config**   
2. /etc/luadns-ddns.conf   
3. /path/to/script/directory/luadns-ddns.con   

It is read in the above order of preference. If the **-c** option is not used, the script will initially try **/etc/luadns-ddns.conf**, and if that doesn't
exist it will fall back to the same directory as the script. If the config file can't be found there, the script will exit with an error. 

The config file parameters are discussed in more detail below:

# public\_ip\_source

How does the script obtain the Public IP? As mentioned above, this can be set to three methods:

1. Local Interface: If the script is ran on a system with a Public IP directly on one of its interfaces for example, a firewall, the script can obtain the IP directly from the interface itself.
This is the best option to use if the system already has a Public IP.

2. HTTP Server: Sends a HTTP or HTTPS request to an internet based server that returns the IP in Plain TXT. Useful if the system that runs the script is behind NAT, or if there are DNS restrictions.

3. DNS Query: There are certain DNS Servers that host DNS records that can be queried directly to obtain ones Public IP address. This is often much faster than the HTTP/HTTPS option, but requires querying the Nameserver
for the corresponding Record(s) directly.

Set to either of these 3 options:

* public\_ip\_source="Local Interface"   
* public\_ip\_source="HTTP Server"   
* public\_ip\_source="DNS Query"   

Depending on what One sets above, further information is required below.

* If using the Local Interface method, specify the name of the interface here.

* If using the HTTP Server Method, comment out the array of HTTP Servers specified here.

* If using the DNS Query Method, comment out the list of commands below. The commands are used as different Nameserver use different methods for determining the
Public IP. Some return TXT records, for others its standard A Records. One should use single quotes ' ' to wrap commands in to ensure all characters are correctly passed in.
In the case of the HTTP Server or DNS Query method the Servers or commands are stepped through one by one until a successful
result is obtained. The below commands have been tested, but one is free to use their own commands if desired.

Examples:

```
public_ip_interface="enp1s0"

public_ip_http_servers=(
 "https://ifconfig.me"
 "https://ifconfig.co"
 "https://icanhazip.com"
 "https://ipecho.net/plain"
)

public_ip_dns_commands=(
  'dig @resolver1.opendns.com myip.opendns.com A -4 +short'
  'dig @ns1.google.com o-o.myaddr.l.google.com TXT -4 +short | tr -d \"'
  'dig @1.1.1.1 whoami.cloudflare TXT CH -4 +short | tr -d \"'
  'dig @ns1-1.akamaitech.net whoami.akamai.net A -4 +short'
)
```

# times\_to\_update

Its useful to have the script update the desired records regardless at certain times throughout the day. This helps ensure the records
are always updated and reachable.

Recommended to leave unchanged as it should match what is in **/etc/systemd/system/luadns-ddns.timer** 
If these are changed, then the timer file needs to be changed also.

Example - Must be an array as per bash syntax, with the times specified as ***HH:MM***.

```
times_to_update=(
  "00:00"
  "02:00"
  "04:00"
  "06:00"
  "08:00"
  "10:00"
  "12:00"
  "14:00"
  "16:00"
  "18:00"
  "20:00"
  "22:00"
)
```
### luadns\_email

This is the logon email for your **Luadns.com** account.

### luadns\_api\_key

This is the api key with access to the zone housing the record(s) one wishes to use with the script. It can be created via the WebUI after logging into **Luadns.com**.

### dns\_zone\_name

Specify the Zone Name. If for example the record is "DDNS1.zone1.org", the Zone Name is "zone1.org" in this example. This allows the script
to be more simple as it does not have to query the Public Suffix List to determine the correct zone name. Note that while the script can
update several DNS A Records at once, they all must be part of the same DNS Zone. Ex: ddns1.zone1.org, ddns2.zone1.org etc. The script will
exit in error if this is not the case.

* dns\_zone\_name="example.org"

### dns\_record\_names

Specify the DNS Records that will be updated at **Luadns.com**. Keep brackets to define as an array. Add as many as desired, the script does not
impose a limit.

To defined multiple use the following:

* record\_names=( "record1.example.org" "record2.example.org" ... )

For a Single Record, use the following:

* record\_names="record1.example.org"

Alternatively specify them like so:

```
dns_record_names=(
  "record1.example.org"
  "record2.example.org"
   ...
)
```

### outgoing\_interface\_ip
 
Use a non-default local network interface for talking to the Luadns API and for querying the records to verify an update has been successful.

This option should not be needed for most default setups. This option can be useful in the event one is running the script on a system behind a firewall
with multiple local network interfaces whereby a different Public IP is reachable depending on which interface is used.

An example could be a Dual WAN Setup, a Firewall that uses Policy Based Routing for different WAN connections, or if one is using a VPN
and wishes the record to reflect the Public IP of the VPN instead.

This could also be useful if one is using a VPN as certain VPN providers do things like Hijack ones DNS requests leading to undesirable results when
querying the Luadns nameservers directly.

Must be a valid IPv4 address of a Local Interface. Comment out if not using

Example:

* outgoing\_interface\_ip="192.168.1.4"

### email\_address

This is the email address notification emails are sent to. To disable emails
and rely on the notification hook instead, comment this out.

### muttrc\_path

This is the path to the **muttrc** file to allow **mutt** to send the notification
emails. Some samples are provided in the docs directory - see below. If this is left empty,
no notification emails are sent.

### notification\_hook

If one wishes to use an alternative form of notification either in addition to
or instead of standard emails a path to a custom notification hook can be
specified here.

This can be a bash script or anything that is called from the command line and
accepts the below arguments. Must be executable.

The notification hook is called like so:

* **$ /path/to/notification/hook "Subject" "/path/to/body-file"**

The body file above is a path to a TXT file containing the text that would form the body of the notification. The
notification hook is primarily intended for services like **ntfy**, **Signal**, **Telegram** or **XMPP** that is
more suited a short message than the full Text of the mail. As a result, the script will pass a more concise
body of text to the notification hook.

If any variables are required for the notification hook, they can be specifed in the
config file with the use of export. Example:

* **export ntfy_url="https://ntfy.sh/channel_name"**

Note not to forget the "export".

A sample notification hook for use with **https://ntfy.sh** is provided here:

* [https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/ntfy-hook.sh](https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/ntfy-hook.sh)

As before, a sample config file can be found here:    

- [https://github.com/zoot101/luadns-ddns/blob/main/config/luadns-ddns.conf](https://github.com/zoot101/luadns-ddns/blob/main/config/luadns-ddns.conf)

# Step 3 - Setting Up Email Notifications

A valid muttrc configuration is required to send email notifications.

A number of sample configurations can be found here:   

- [https://github.com/zoot101/luadns-ddns/tree/main/docs/muttrc-examples](https://github.com/zoot101/luadns-ddns/tree/main/docs/muttrc-examples)

The following sample configurations are provided:

* Gmail Using App Passwords    
* Outlook Using Oauth2    
* Gmail Using Oauth2    

See the above for much more detailed instructions on setting it up.

## Email Notifications on IPFire

As mentioned above, sending emails is not possible on IPFire using **mutt** as it is not provided in the IPFire repos. However one can use the following hook script
created by the author to send emails.

- [https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/send-email-ipfire.sh](https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/send-email-ipfire.sh)

First set up a valid email configuration using the Firewall's WebUI. See the official documentation here:

- [https://www.ipfire.org/docs/configuration/system/mail\_service](https://www.ipfire.org/docs/configuration/system/mail_service)

To use it, do the following:

```bash
mkdir /opt/ipfire-hooks
cd /opt/ipfire-hooks
wget https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/send-email-ipfire.sh
chmod +x send-email-ipfire.sh
```

Now in the main config (**/etc/luadns-ddns.conf**), do the following:
```bash

# Comment out the standard email parameters like so:
#email_address="mail@example.com"#
#muttrc_path="/path/to/muttrc/path"

# Notification Hook
# Specify the path to the above address and export the email you want
# to receive email notifications at
notification_hook="/opt/ipfire-hooks/send-email-ipfire.sh"
export email_address="mail@example.comf"
```

## Custom Notification Hook - ntfy

An example custom notification hook that can be used to send notifications
to **ntfy** is included here:

- [https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/ntfy-hook.sh](https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/ntfy-hook.sh)

To use it, do the following:

```bash
sudo mkdir /opt/luadns-ddns-hooks
cd /opt/luadns-ddns-hooks
sudo wget https://raw.githubusercontent.com/zoot101/luadns-ddns/refs/heads/main/docs/examples/ntfy-hook.sh
```

Then put the following in the config file (/etc/luadns-ddns.conf)

```bash
export ntfy_url="https://ntfy.sh/channel_name"
notification_hook="/opt/luadns-ddns-hooks/ntfy-hook.sh"
```

See ntfy documentation here: [https://docs.ntfy.sh](https://docs.ntfy.sh)

# Step 4 - Call the Script Directly

After the above steps have been carried out and the config file has been setup,
one is ready to run the script directly.

Call it from the command line like so. It is recommended that this be done as the user that
you intend the script to run as.

```bash
luadns-ddns
```

To test the update function, the easiest thing to do is invoke the -f, \--force
option detailed above.

```bash 
luadns-ddns -f
```
A sample output for the case for an IP change is shown below.

```bash
##############################
# Luadns.com DDNS Version: 2.0.0
##############################
Initialized at 09:40:16 on 21/09/2026
 * Luadns.com API URL: https://api.luadns.com/v1
 * Hostname: firewall.example.org
 * Host OS: Debian GNU/Linux 13 (trixie)
Input Options:
 * Public IP Source: Local Interface: pppoe-wan
 * DNS Zone Name: example.org
 * DNS Records to Update:
   - media.example.org
   - xmpp.example.org
 * Email Notifications: YES
 * Notification Hook: YES
Runlog is below:

Update the DNS Record(s) Regardless?
 * No

Checking Public IP...
 * Checking IP on Interface: pppoe-wan
 * Got Public IP: 1.2.3.4
 * IP Change Detected!
    - Last IP: 1.2.3.2
    - New IP: 1.2.3.4
 * Proceeding to Update Record(s)...

Updating DNS Record(s)...
 * Got Valid NS records for example.org from ns1.luadns.net
 * Got Valid Zone ID for example.org from LuaDNS API
 * Updating Record 1/2: media.example.org...
    - Got Valid Record ID
    - Record updated to 1.2.3.4
 * Updating Record 2/2: xmpp.example.org...
    - Got Valid Record ID
    - Record updated to 1.2.3.4

Verifying Updated DNS Record(s)...
 * Querying LuaDNS Nameservers for media.example.org...
    - Record live on ns1.luadns.net
    - Record live on ns2.luadns.net
    - Record live on ns3.luadns.net
    - Record live on ns4.luadns.net
 * Querying LuaDNS Nameservers for xmpp.example.org...
    - Record live on ns1.luadns.net
    - Record live on ns2.luadns.net
    - Record live on ns3.luadns.net
    - Record live on ns4.luadns.net
 * Success! All Updated Record(s) now Live!

Regards,
firewall.example.org
```

Once the script is confirmed working, one can move on to systemd setup below.

## Step 5 - Automation with Systemd

By default the following files are bundled with the package installation:

* **/usr/lib/systemd/system/luadns-ddns.service**       
* **/usr/lib/systemd/system/luadns-ddns.timer**  

For manual installations they will be in **/etc/systemd/system** instead.

There should be no need to modify either of them, and it is especially
recommended NOT to modify the timer file as the times to run match what
are specifed in the script itself. However, in the event that one DOES
want to edit them, the best thing to do is create a copy
at **/etc/systemd/system**.

During the debian package installation, the user is prompted to run the
script as a user other than root if desired. This creates a drop-in file here:

* **/etc/systemd/system/luadns-ddns.service.d/user.conf**

It is advised to test running the script via systemd 1st before enabling the
timer. To do that, do the following (as root):

```bash
sudo systemctl start luadns-ddns.service
```

Its a good idea to have a look at the logs using journalctl to confirm it is
working as expected.

```bash
sudo journalctl -u luadns-ddns --since today
```

If the above is as expected, the next thing is to start the timer like so:   

```bash
# Start the Timer
systemctl start luadns-ddns.timer 

# Enable the Timer at Startup
systemctl enable luadns-ddns.timer
```    

Confirm that it is running by looking here:

```bash
systemctl list-timers
```

That is it - Thank you for your interest in this script and hopefully it is
of use to you! Bug reports here on github are welcomed - don't hesitate if you find something
wrong.

## Step 5 for IPFire - Cron Setup

To get the script running via cron on IPFire, see the below page:

[https://github.com/zoot101/luadns-ddns/tree/main/docs/cron-examples](https://github.com/zoot101/luadns-ddns/tree/main/docs/cron-examples)

# Further Examples

Some examples are provided for **muttrc** configuration files along with
systemd drop-in files here:

- [https://github.com/zoot101/luadns-ddns/tree/main/docs/muttrc-examples](https://github.com/zoot101/luadns-ddns/tree/main/docs/muttrc-examples)
- [https://github.com/zoot101/luadns-ddns/tree/main/docs/systemd-dropins](https://github.com/zoot101/luadns-ddns/tree/main/docs/systemd-dropins)

# Issues

Bug reports here on Github are welcome - don't hestitate if you find something wrong.

* [https://github.com/zoot101/luadns-ddns/issues](https://github.com/zoot101/luadns-ddns/issues)

