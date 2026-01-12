#!/usr/bin/env bash

###################################################
#
# Sample hook script to send notifications to ntfy
# To use put the following in /etc/luadns-ddns.conf
#
# notification_hook="/path/to/ntfy-hook.sh"
# export ntfy_url="https://ntfy.sh/channel_name"
#
# Change the URL if you are selfhosting ntfy
#
###################################################

# Main Function
main() {

  # Arguments
  local notification_title="${1}"
  local notification_body=$(cat "${2}")
  local notification_attachment="${3}"

  # Check for an ntfy url
  if [ -z "${ntfy_url}" ]
  then
    echo "ERROR: No ntfy_url defined - Exiting"
    echo "Require export ntfy_url=\"https://ntfy.sh/channel_name\" in config file"
    exit 1
  fi

  # If no attachment - Single Notification Only
  echo "Sending notification to ${ntfy_url}..."
  curl --silent --retry 3 -H "Title: ${notification_title}" \
                          -d "${notification_body}" \
                          "${ntfy_url}" &> /dev/null

  # If an attachment is present - send that as a file
  if [ ! -z "${notification_attachment}" ]
  then
    # Invoke some wait time
    sleep 3

    # Send Attachment as File via ntfy
    echo "Sending attachment to ${ntfy_url}..."
    curl --silent --retry 3 -T "${notification_attachment}" \
                            -H "Filename: "${notification_attachment}"" \
                            "${ntfy_url}" &> /dev/null
  fi
}

# Call main function
main "$@"

