---
title: luadns-ddns
section: 1
header: User Manual
footer: luadns-ddns
---

# NAME

luadns-ddns - DDNS Client implemented as a Simple Bash Script that uses the Luadns.com
REST API, with email notifications.

# SYNOPSIS

Usage:

**luadns-ddns**

(No Options) OR:

**luadns-ddns [OPTIONS...]**

## VALID OPTIONS

### -c \--config

Override default config file. Example:

* **$ luadns-ddns -c /path/to/other/config/file.conf**

### -f \--force

Force an update to the API Server regardless of time or whether an IP change
was detected or not. (Useful for debug/testing)

### -h \--help

Print Short Help Message and exit.

# DESCRIPTION

This is a DDNS service implemented as a relatively simple bash script that tracks the
Public IP using a number of publically available websites that output the IP in plain text
like **icanhazip.com** or **ifconfig.co**.

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

* https://www.luadns.com/dyndns.html

Note that the script only supports Type A DNS Records (IPv4 Addressing Only), IPv6 (AAAA) is
not supported.

# GETTING STARTED

A guide to getting started with the script is shown below:

## STEP 1 - UP-FRONT REQUIREMENTS

To use this script the following is requried up front:

* Ownership of a valid domain name    
* Luadns servers (ns[1-4].luadns.net) configured for the Domain at your Domain Registrar   
* API access enabled in the Luadns.com account settings    
* A valid API Key created for the zone in question (record.example.org: example.org is the zone)    
* A Type DNS Records (IPv4) created at Luadns.com for use with the script    

The finer details about the above are not considered here and left up to the user.

## STEP 2 - CONFIG FILE SETUP

The next thing that is required is to configure the config file for the script.

A description of what is required in the config file is shown here.

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
no notification emails are sent.

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

* **export ntfy_url="https://ntfy.sh/channel_name"**

Note not to forget the "export".

A sample notification hook for use with **https://ntfy.sh** is provided here:

* **/usr/share/doc/luadns-ddns/examples/ntfy-hook.sh**

# STEP 3 - SETTING UP EMAIL NOTIFICATIONS

A valid muttrc configuration is required to send email notifications.

A number of sample configurations can be found here:    
**/usr/share/doc/luadns-ddns/muttrc-examples/**

The following sample configurations are provided:

* Gmail Using App Passwords    
* Outlook Using Oauth2    
* Gmail Using Oauth2    

See the readme file (README.md) in the above directory, for much more detailed
instructions on setting it up.

Setting up the custom notification hook is left to the user and not considred here.

# STEP 4 - CALL THE SCRIPT

After the above steps have been carried out and the config file has been setup,
one is ready to run the script directly.

Call it from the command line like so:

* **$ luadns-ddns**

To test the update function, the easiest thing to do is invoke the -f, \--force
option detailed above.

* **$ luadns-ddns -f**

A sample output for the case where no update is found is shown below:

```bash

######################################
# Luadns.com DDNS Version: 1.0.0
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
# Luadns.com DDNS Version: 1.0.0
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

## STEP 5 - AUTOMATION WITH SYSTEMD

By default the following files are bundled with the package installation:

* **/lib/systemd/system/luadns-ddns.service**       
* **/lib/systemd/system/luadns-ddns.timer**  

There should be no need to modify either of them, and it is especially
recommended NOT to modify the timer file as the times to run match what
are specifed in the script itself. However, in the event that  one DOES
want to edit them, the best thing to do is create a copy
at **/etc/systemd/system**.

During the debian package installation, the user is prompted to run the
script as a user other than root if desired. This creates a drop-in file here:

* **/etc/systemd/system/luadns-ddns.service.d/user.conf**

It is advised to test running the script via systemd 1st before enabling the
timer. To do that, do the following (as root):

* **$ systemctl start luadns-ddns.service**

Its a good idea to have a look at the logs using journalctl to confirm it is
working as expected.

* **$ journalctl -u luadns-ddns --since today**

If the above is as expected, the next thing is to start the timer like so:   

* **$ systemctl start luadns-ddns.timer**   
* **$ systemctl enable luadns-ddns.timer**    

Confirm that it is running by looking here:

* **$ systemctl list-timers**

That is it - Thank you for your interest in this script and hopefully it is
of use to you!

# FURTHER EXAMPLES

Some examples are provided for **muttrc** configuration files along with
systemd drop-in files here:

* /usr/share/doc/luadns-ddns/systemd-dropins/   
* /usr/share/doc/luadns-ddns/muttrc-examples/   

# AUTHOR

Mark \<mark9000@fastmail.org\>

# SEE ALSO

Luadns.com REST API Documentation
https://www.luadns.com/api.html

# ADDITIONAL MAN PAGES

curl(1), mutt(1), muttrc(1), jq(1), systemd.unit(5), journalctl(1), sync-dns-records(1)

