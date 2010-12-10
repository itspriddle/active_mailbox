require 'active_mailbox/version'
require 'active_mailbox/errors'
require 'active_mailbox/mailbox'
require 'active_mailbox/folder'
require 'active_mailbox/message'

module ActiveMailbox
  # The directory Asterisk records voicemail in
  #
  # By default, this is `/var/spool/asterisk/voicemail`. If it isn't,
  # you did something fancy when building Asterisk. Set
  # ENV['ASTERISK_VOICEMAIL_ROOT'] to that directory in your library
  # or add 'export ASTERISK_VOICEMAIL_ROOT="/my/voicemail"' to your
  # ~/.bashrc
  VOICEMAIL_ROOT = ENV['ASTERISK_VOICEMAIL_ROOT'] || "/var/spool/asterisk/voicemail"
end
