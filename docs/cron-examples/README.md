# Luadns-DDNS - IPFire Automation Setup

Most systems running this script will likely use systemd.
However below are some notes to get it going on systems with cron. **IPFire**
is particularly relevant here.

Setting up of cron itself is left to the user and not considered here.

* To emulate the default installation, put the script somewhere along most users $PATH variables - /usr/bin/ usually.   
* Put the config file in /etc.   
* Alternatively put the script and config file in their own directory somewhere. The config file will be read by the script if its in the same directory.   

## Cron Tab Line Example

The below should work assuming the script is in **/usr/bin**, change the path accordingly. Note the times
should match the **times_to_update** setting in the config file.

```bash
00,10,20,30,40,50 * * * * "/usr/bin/luadns-ddns"
```

etc...

(Change the path to the script above if needed)

There are many good crontab generators online if one has a search,
here is one such example:

[https://crontab-generator.org](https://crontab-generator.org)

To set the script up on IPFire follow the below procedure. One could get the script to
run as root to not have to generate a new user, but this is not ideal as the default
crontab is prone to being updated for subsequent versions of **IPFire**.

## Step 1 - Allow the non-root user to use the Cron daemon

Proceeding on from the main README where a user (user1 as an example) was created,
edit **/etc/fcron.allow** and add **user1** to it.

```bash
# Edit /etc/fcron.allow
nano /etc/fcron.allow

# It should look something like this:
root
user1
```

## Step 3 - Create a fcrontab for user1

Do the following:

```bash
# Create a crontab for user1
fcronuser -u user1 -e

# Then paste in the following entry from above,
# save and close
00,02,04,06,08,10,12,14,16,18,20,22 00,10,20,30,40,50 * * * "/usr/bin/luadns-ddns"
```

## Step 4 - Test it Out

Sometimes it can be difficult to know the script is actually running,
to help with that one can check the **/var/lib/luadns** directory for the logfiles
the script will generate:   

```bash
# See below - note the time of the generated files

user @ firewall : ~ $ ls -lah /var/lib/luadns-ddns
total 52K
drwxrwxr-x  2 username nas-users 4.0K Jul 22 00:00 .
drwxr-xr-x 50 root root      4.0K Jul 22 17:59 ..
-rw-r--r--  1 username nas-users   26 Jul 14 11:46 ip_log_2025-07-13.log
-rw-r--r--  1 username nas-users 1.2K Jul 14 23:50 ip_log_2025-07-14.log
-rw-rw-r--  1 username nas-users 3.7K Jul 15 23:50 ip_log_2025-07-15.log
-rw-rw-r--  1 username nas-users 3.7K Jul 16 23:50 ip_log_2025-07-16.log
-rw-rw-r--  1 username nas-users 3.7K Jul 17 23:50 ip_log_2025-07-17.log
-rw-rw-r--  1 username nas-users 3.7K Jul 18 23:50 ip_log_2025-07-18.log
-rw-rw-r--  1 username nas-users 3.7K Jul 19 23:50 ip_log_2025-07-19.log
-rw-rw-r--  1 username nas-users 3.7K Jul 20 23:50 ip_log_2025-07-20.log
-rw-rw-r--  1 username nas-users 3.7K Jul 21 23:50 ip_log_2025-07-21.log
-rw-rw-r--  1 username nas-users 3.2K Jul 22 20:20 ip_log_2025-07-22.log
-rw-r--r--  1 username nas-users   15 Jul 14 16:42 last-ip-check.txt
# etc.
```

