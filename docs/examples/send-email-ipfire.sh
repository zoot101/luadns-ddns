#!/usr/bin/env bash

###################################################
# SEND-EMAIL HOOK
###################################################
# Simply send an email from the command line
#
# Firstly configure the settings here via the WebUI:
# https://firewall.home.lan:444/cgi-bin/mail.cgi
#
# Then to use include this in the parent script or the parent
# scripts config:
# export email_address="example@email.org"
#
# Call the Script by doing:
# send-email-ipfire "Email Subject" "/path/to/file/containing/email/body"
#
# Or to Attach a file do:
# send-email-ipfire "Email Subject" "/path/to/file/containing/email/body" "/path/to/attachment"
#
#
###################################################
# Main Function
###################################################
main() {
  # Check for Email Address and Required Arguments
  if [ -z "${email_address}" ]
  then
    echo "ERROR: No email_address specified - Require \"export email_address=mail@ex.org\" in parent script config"
    exit 1
  elif [ -z "${1}" ]
  then
    echo "ERROR: No Email Subject Specified"
    echo "Usage: send-email-ipfire <subject> <path-to-body> <path to attachment (optional)>"
    exit 1
  elif [ -z "${2}" ]
  then
    echo "ERROR: No Email Body File Specified"
    echo "Usage: send-email-ipfire <subject> <path-to-body> <path to attachment (optional)>"
    exit 1
  fi 

  # Input Arguments
  subject="${1}"
  body_file="${2}"
  attachment="${3}"

  # Send Email without Attachment if no 3rd arg is present
  if [ -z "${attachment}" ]
  then
    echo "Sending email to" "${email_address}""..."
    send_email "${email_address}" "${subject}" "${body_file}"
  else
    echo "Sending email to" "${email_address}" "with attachment:${attachment}"
    send_email "${email_address}" "${subject}" "${body_file}" "${attachment}"
  fi

  # Check Return Code
  if [ $? == 0 ]
  then
    echo "Email Sent Successfully"
  else
    echo "Problem Sending Email..."
  fi
}

# Send Email Function
send_email() {
  ###################################
  # SEND EMAIL FUNCTION
  ###################################

  # Usage:
  # $ send_email <email address> <Subject> <Path to Body File> <Attachment (if desired)>

  # Parse Arguments
  email_address="$1"
  email_subject="$2"
  email_body_file="$3"
  email_attachment="$4"

  # Pull Out Filename from Full Path Specified Above
  attachment_filename=$(echo $email_attachment | sed "s/.*\///")

  ###################################
  # Case 1 - Attachment is Present
  ###################################

  if [ ! -z "$4" ]
  then
    # Construct the Appropriate Input File for DMA below,
    # Then Pipe to dma to send
    (
      echo "Date: $(date -R)"
      echo "To: $email_address"
      echo "Subject: $email_subject"
      echo "MIME-Version: 1.0"
      echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
      echo
      echo '---q1w2e3r4t5'
      echo 'Content-Type: text/plain; charset=utf-8'
      echo 'Content-Transfer-Encoding: 8bit'
      echo
      cat $email_body_file
      echo '---q1w2e3r4t5'
      echo 'Content-Type: text/plain; charset=utf-8; name='$attachment_filename
      echo 'Content-Transfer-Encoding: base64'
      echo 'Content-Disposition: attachment; filename='$attachment_filename
      echo
      base64 <"$email_attachment"
      echo
      echo '---q1w2e3r4t5--'
     ) | /usr/sbin/dma $email_address

     ###################################
     # Case 2 - No Attachment is Present
     ###################################

     else
       # Construct the Appropriate Input File for DMA below,
       # Then Pipe to dma to send
       (
         echo "Date: $(date -R)"
         echo "To: $email_address"
         echo "Subject: $email_subject"
         echo "MIME-Version: 1.0"
         echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
         echo
         echo '---q1w2e3r4t5'
         echo 'Content-Type: text/plain; charset=utf-8'
         echo 'Content-Transfer-Encoding: 8bit'
         echo
         cat $email_body_file
            echo '---q1w2e3r4t5'
       ) | /usr/sbin/dma $email_address
     fi
}

###################################################
# Call Main Function
###################################################
main "$@"

