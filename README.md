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

This is a DDNS client implemented as a simple bash script that tracks the
Public IP using a number of publically available websites that output the IP in plain text
like [icanhazip.com](https://icanhazip.com) or [ifconfig.co](https://ifconfig.co)

It keeps track of the Public IP it receives from those servers and monitors it for changes. If
changes are detected, it will update a corresponding DNS Record at **Luadns.com** using their
REST API Server.

It will notify the user of an IP Change via email or through the use of a custom notification hook
(if configured). The user is also notified the very 1st time the Script
is ran. Emails are sent using **mutt**.

An optional custom notification hook is also supported to allow the user to use an alternative form
of notification in addition to or instead of the standard emails if desired (see below).

The script will also update the DNS Record at **Luadns.com** at certain times regardless of whether
a change in the Public IP is detected or not. This ensures the DNS Record is kept up to date
at all times regardless of the circumstances.

It is intended to be ran as a scheduled task via systemd or cron job. The default implementation
(if installed by the package) is to run every 10 minutes.

Updating multiple records is also supported. This is to handle the situation whereby multiple
records point to the same IP address which is dynamic and can change. 

Usually in this situation one would get a DDNS client to update a single record, and change all
of the other records to CNAMEs to point to the former record.

This works but CNAME records increase the amount of queries. The script presents an alternative
to this by supporting the update of multiple records at once. However it is assumed that if multiple
records are being used, all are part of the same DNS **Zone**, that is they are of the
following shape:

* record-to-update1.mydomain.org    
* record-to-update2.mydomain.org    
* record-to-update3.mydomain.org    

If multiple records are specified and they are **NOT** part of the same DNS **Zone**, the script
will exit with an error. If it is desired to update records on multiple DNS **Zones**, then it
is best create a different config file and use **-c** option as specified below.

The script also provides the capability to log the public IP each time it is called. The logs
are kept around for 28 days and then deleted, this can be useful if for some reason access to
the raw IP address is needed or the API server cannot be contacted (rare!). The log can also be
sent via email/notification hook if the user desires.

Luadns.com do mention using ddclient on their documentation (see below link), but since
the author created a hook script for **dehydrated** for use with **Luadns.com**, it was
a natural progression to create this DDNS update script.    

* [https://www.luadns.com/dyndns.html](https://www.luadns.com/dyndns.html)

Note that the script only supports Type A DNS Records (IPv4 Addressing Only), IPv6 (AAAA) is
not supported.

# Usage

```bash
Usage: luadns-ddns            [OPTIONS...]

  -f, --force                 Force an update of the record regardless of time or
                              whether an IP Change is detected
  -c, --config                Override the default config file. Could be useful to
                              update multiple records
  -h, --help                  Print help

The script can also be called with no options like so:

 $ luadns-ddns
```

# Installation

Two methods are available for installation - via the debian package or manually.

A package is provided for Debian and its derivatives. The author has tested this
on Debian Bullseye (11), Debian Bookworm (12), and Debian Trixie (13), Fedora 42 and
IPFire (2.29 - Core 195).

## Package Installation - Debian Based Distros

To install the package (for Debian based distros), download it from the releases
page [HERE](https://github.com/zoot101/luadns-ddns/releases) and do the following.
Note that it's better to use **apt** rather than **dpkg** so the dependencies will be automatically installed.

```bash
sudo apt install ./luadns-ddns_1.0.2-1_amd64.deb
```
During the package installation, the user is prompted to select a user other
than root to run the script if desired.

Then proceed to the **Getting Started** section below.

## Manual Installation - Other Distros

First download the latest source code archive from the releases page [HERE](https://github.com/zoot101/luadns-ddns/releases).
and extract it, then do the below: 

```bash
unzip luadns-ddns-1.0.2.zip      # For the Zip File
tar xvf luadns-ddns-1.0.2.zip    # For the Tar File

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
unzip luadns-ddns-1.0.2.zip       # For the Zip File
tar xvf luadns-ddns-1.0.2.tar.gz  # For the Tar File

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

A description of what is required in the config file is shown here. A sample config
file can be found here:    
- https://github.com/zoot101/luadns-ddns/blob/main/config/luadns-ddns.conf

The config file should be specified in one of the following 3 ways:

1. Via the -c, \--config option - Example: **$ luadns-ddns -c /path/to/config**   
2. /etc/luadns-ddns.conf   
3. /path/to/script/directory/luadns-ddns.con   

It is read in the above order of preference. If the **-c** option is not used,
the script will initially try **/etc/luadns-ddns.conf**, and if that doesn't
exist it will fall back to the same directory as the script. If the config
file can't be found there, the script will exit with an error. 

Shown below is a simplified sample configuration file. By default the Script
will place a sample config file at **/etc/luadns-ddns.conf** with explanatory
comments that can be edited accordingly. 

```bash
# List of URLS to Check Public IP
ip_check_urls=( "ifconfig.me" "ifconfig.co" "icanhazip.com" )

# Times to Update Regardless of IP Change
times_to_update=( "00:00" "04:00" "08:00" "12:00" "16:00" "20:00" )

# Luadns.com Account Credentials
lua_email=email@example.org
lua_api_key="1234567890abcedfghi....yzlump"

# DNS Record(s) details
# Update a Single Record
record_names="record-to-update.mydomain.org"

# Update Multiple Records (No Limit is enforced by the script)
#record_names=( "record-to-update1.mydomain.org" "record-to-update2.mydomain.org" )

# Email notifications (To disable emails comment these out)
email_address=receive.notifications.here@example.org
muttrc_path="/path/to/muttrc/file"

# Enable IP Logging (Comment out or set to no if not using)
#ip_logging="yes"
#notify_with_log="yes"

# Notification Hook (Comment out or set to no if not using)
#notification_hook="/path/to/notification/hook"

# Hook Variables
# If any variables are required by the above hook specify them here with "export"
#export var1="whatever"

```

The config file parameters are discussed in more detail below:

### ip\_check\_urls

This is an array of URLs that can be queried with **curl** to get
an output of ones public IPv4 address in plain txt. It can be changed,
but in the authors experience the values populated in the default config
file work quite well.

Must be specified as an array like so:

* ip\_check\_urls=( "url1" "url2" "url3" ) 

The script will initially try the 1st link specifed to get the Public IP address,
failing that it will move on to the next one and so on. If all urls either can't
be contacted or do not reply with a valid IPv4 address, the script will exit
with an error.

### times\_to\_update

A list of times that the script will update the record(s) regardless of
whether there is a public IP change detected or not. This always ensures
the record is kept up to date.

It is **NOT** recommended to change this as it needs to match what is defined
in **/etc/systemd/system/luadns-ddns.timer** to function as expected.

Must be specified as an array with times in the following format (HH:MM)

* times\_to\_update=( "00:00" "04:00" "10:00" .... "20:00" )

### lua\_email

This is the logon email for your **Luadns.com** account.

### lua\_api\_key

This is the api key with access to the zone housing the record(s) one wishes
to use with the script. It can be created via the WebUI after logging into
**Luadns.com**.

### record\_names

This is either a single DNS record or a list of DNS records that one wishes
to use as the DDNS record(s). Before using the script, each record should be
created as type A with an IP address defined, which can be anything as the
script will update it accordingly.

This should be done via the **Luadns.com** WebUI or otherwise.

To define a single record use:

* **record_name="ddns1.example.org"**

To define multiple records to update, use an array like so:

* **record_name=( "ddns1.example.org" "ddns2.example.org" ... "ddnsN.example.org" )**

### email\_address

This is the email address notification emails are sent to. To disable emails
and rely on the notification hook instead, comment this out.

### muttrc\_path

This is the path to the **muttrc** file to allow **mutt** to send the notification
emails. Some samples are provided in the docs directory. If this is left empty,
no notification emails are sent. See the section below on Email Notifications for
more detailed instructions on setting this file up.
- https://github.com/zoot101/luadns-ddns/tree/main/docs/muttrc-examples

### ip\_logging

This can be enabled to keep a daily log of the public IP address stretching back
28 days. Valid values are \"yes\" or\"no\". Comment out or set to \"no\" to disable.

### notify\_with\_log

Each time the script is called for the 1st time in a day, it will send an email
and/or call the custom notification hook (if configured) to send the user the log
of all IP addresses recorded the previous day as an attachment.

The idea behind this is that if the API Server cannot be contacted, one can
fall back to the IP log sent by email.

Valid values are \"yes\" or \"no\". Comment out or set to no if not using. Has no
effect if the **ip_logging** setting above is not enabled.

### notification\_hook

If one wishes to use an alternative form of notification either in addition to
or instead of standard emails a path to a custom notification hook can be
specified here.

This can be a bash script or anything that is called from the command line and
accepts the below arguments. Must be executable.

The notification hook is called like so:

* **$ /path/to/notification/hook "Email Subject" "Email Body"**

In the case that the logging function is enabled and the **notify_with_log**
setting is being used, the notification hook is called like so:

* **$ /path/to/notification/hook "Email Subject" Email Body" "Email Attachment"**

Comment out if not using.

If any variables are required for the notification hook, they can be specifed in the
config file with the use of export. Example:

```bash
export ntfy_url="https://ntfy.sh/channel_name"
```

Note not to forget the "export".

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

As mentioned above, sending emails is not possible on IPFire using **mutt** as it
is not provided in the IPFire repos. However one can use the following hook script
created by the author to send emails.

- [https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/send-email-ipfire.sh](https://github.com/zoot101/luadns-ddns/blob/main/docs/examples/send-email-ipfire.sh)

First set up a valid email configuration using the Firewall's WebUI. See the official
documentation here:

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
A sample output for the case where no update is found is shown below:

```bash

######################################
# Luadns.com DDNS Version: 1.0.2
######################################
# Luadns.com API URL: https://api.luadns.com/v1
# Record Name 1/1: server-ddns.example.org
# Zone Name: example.org
# Logging Enabled: YES
# Force Update: NO
# Email Notifications: YES
# Notification Hook: NO
#####################################

Checking Zone is valid and hosted at Luadns.com
 + Success: Got Valid NS records for example.org from ns1.luadns.net
Checking Public IP using the supplied urls...
 + Public IP determined to be 1.2.3.4 using ifconfig.me
IP Logging Enabled
 + Logging Public IP 1.2.3.4
Checking for Public IP Change
 + Old Public IP     : 1.2.3.4
 + Current Public IP : 1.2.3.4
 + IP Change Not Detected
No Update needed
Removing /tmp files...

```

Here is a sample output for the case where the record is updated as a
result of an IP Change being detected.

```bash
INFO: Config File: /etc/luadns-ddns.conf

######################################
# Luadns.com DDNS Version: 1.0.2
######################################
# Luadns.com API URL: https://api.luadns.com/v1
# Record Name 1/1: server-ddns.example.org
# Zone Name: example.org
# Logging Enabled: YES
# Force Update: NO
# Email Notifications: YES
# Notification Hook: NO
#####################################

Checking Zone is valid and hosted at Luadns.com
 + Success: Got Valid NS records for example.org from ns1.luadns.net
Checking Public IP using the supplied urls...
 + Public IP determined to be 1.2.3.4 using ifconfig.me
IP Logging Enabled
 + Logging Public IP 1.2.3.4
Checking for Public IP Change
 + Old Public IP : 1.2.3.3
 + New Public IP : 1.2.3.4
 + IP Change Detected - Proceeding to Update

Updating 1 Record(s) [IP Change Detected]
 + Last IP: 1.2.3.3
 + New IP: 1.2.3.4
 + Contacting Luadns.com REST API: https://api.luadns.com/v1
 + Getting Zone ID for example.org
 + Found Zone ID: 1001
 + Updating Record 1/1
  -> Getting Record ID for server-ddns.example.org
  -> Found Record ID: 100101
  -> Updating nas-ddns.example.org
  -> API Server Reply: Updated Successfully to 1.2.3.4
 + New IP: 1.2.3.4 recorded for next run

Sending Notification Email to user-email@example.com...
 + Notification Email sent successfully...

Removing /tmp files...
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

[https://github.com/zoot101/luadns-ddns/edit/main/docs/cron-examples](https://github.com/zoot101/luadns-ddns/edit/main/docs/cron-examples)

# Further Examples

Some examples are provided for **muttrc** configuration files along with
systemd drop-in files here:

- [https://github.com/zoot101/luadns-ddns/tree/main/docs/muttrc-examples](https://github.com/zoot101/luadns-ddns/tree/main/docs/muttrc-examples)
- [https://github.com/zoot101/luadns-ddns/tree/main/docs/systemd-dropins](https://github.com/zoot101/luadns-ddns/tree/main/docs/systemd-dropins)

# Issues

Bug reports here on Github are welcome - don't hestitate if you find something wrong.

* [https://github.com/zoot101/luadns-ddns/issues](https://github.com/zoot101/luadns-ddns/issues)

