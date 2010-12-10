module ActiveMailbox
  module Errors #:nodoc: all
    class MailboxNotFound  < StandardError; end
    class MessageNotFound  < StandardError; end
    class FolderNotFound   < StandardError; end
    class GreetingNotFound < StandardError; end
  end
end
