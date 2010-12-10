module ActiveMailbox
  #
  # The ActiveMailbox::Mailbox class represents a top-level Asterisk
  # mailbox. A mailbox contains folders, which contain the actual
  # voicemails.
  #
  class Mailbox
    #
    # Greetings that can be altered by ActiveMailbox
    #
    ValidGreetings = [:unavail, :temp, :greet]

    include Comparable

    class << self
      #
      # The Mailbox currently in use
      #
      attr_accessor :current_mailbox

      #
      # Find mailbox
      #
      # On a default Asterisk installation, this would be
      # /var/spool/asterisk/voicemail/CONTEXT/MAILBOX
      #
      # Note: if context is not provided, it will be set to mailbox[1, 3],
      #       which is the area code (NPA) on 11 digit phone numbers
      #
      # Usage:
      #   find('15183332220', 'Default') # Specify context 'Default'
      #   find('15183332220')            # Set context to '518' automatically
      #
      def find(mailbox, context = nil)
        if context
          self.current_mailbox = new(mailbox, context)
        else
          self.current_mailbox = new(mailbox, mailbox.to_s[1, 3])
        end
        yield(current_mailbox) if block_given?
        current_mailbox
      end
      alias :[] :find
    end

    attr_reader :mailbox, :context

    #
    # Create a new Mailbox object
    #
    def initialize(mailbox, context)
      @context = context.to_s
      @mailbox = mailbox.to_s

      unless File.exists?(mailbox_path)
        raise ActiveMailbox::Errors::MailboxNotFound, "`#{mailbox_path}` does not exist"
      end
    end

    #
    # Compare based on path name
    #
    def <=>(other)
      mailbox <=> other.mailbox
    end

    #
    # Use method missing to simulate accessors for folders
    #
    # Eg: self.inbox is the same as self.folders[:inbox]
    #
    def method_missing(method_name, *args, &block)
      meth = method_name.to_s.downcase.gsub(/\W/, '_').to_sym
      if folders.has_key?(meth)
        folders[meth]
      else
        super
      end
    end

    #
    # Returns true if method_name is a folder name, or calls super
    #
    def respond_to?(method_name)
      folders.has_key?(method_name.to_s.downcase.gsub(/\W/, '_').to_sym) || super
    end

    #
    # The full filepath to this Mailbox
    #
    def path
      @path ||= mailbox_path
    end

    #
    # A hash/struct of folders in this Mailbox.
    # Keys are the folder name (as a symbol).
    # Values are an array of Message objects
    #
    def folders(reload = false)
      if reload or @reload_folders or ! defined?(@folders)
        @folders = {}
        Dir.chdir(mailbox_path) do
          Dir['*'].each do |folder|
            if File.directory?(folder) && ! ignore_dirs.include?(folder)
              key = folder.downcase.gsub(/\W/, '_').to_sym
              @folders[key] = Folder.new("#{Dir.pwd}/#{folder}", self)
            end
          end
        end
      end
      @folders
    ensure
      @reload_folders = false
    end

    #
    # Return total number of messages in every folder
    #
    def total_messages
      folders.values.inject(0) { |sum, folder| sum += folder.size }
    end

    #
    # Destroy all Messages in this mailbox, but leave Mailbox,
    # Folders, and greetings intact
    #
    def purge!
      folders.each do |name, folder|
        folder.purge!
      end
    end

    #
    # Destroy this Mailbox and all messages/greetings
    #
    def destroy!
      FileUtils.rm_rf(mailbox_path)
    end

    #
    # Sort all Messages in all Folders
    #
    # See ActiveMailbox::Folder#sort! for more info
    #
    def sort!
      folders.each do |name, folder|
        folder.sort!
      end
    end

    #
    # The greeting Asterisk will play
    #
    def current_greeting
      case
      when greeting_exists?(:temp)
        @current_greeting = greeting_path(:temp)
      when greeting_exists?(:unavail)
        @current_greeting = greeting_path(:unavail)
      end
    end

    #
    # Delete greeting
    #
    # Valid options: :unavail, :temp, :busy
    #
    def delete_greeting!(greeting = :unavail)
      if ValidGreetings.include?(greeting)
        greeting_exists?(greeting) && File.unlink(greeting_path(greeting))
      else
        raise ActiveMailbox::Errors::GreetingNotFound, "Invalid greeting `#{greeting}'"
      end
    end

    #
    # Delete temp.wav
    #
    def delete_temp_greeting!
      greeting_exists?(:temp) && File.unlink(greeting_path(:temp))
    end

    #
    # Delete busy.wav
    #
    def delete_busy_greeting!
      greeting_exists?(:busy) && File.unlink(greeting_path(:busy))
    end

    #
    # Delete unavail.wav
    #
    def delete_unavail_greeting!
      greeting_exists?(:unavail) && File.unlink(greeting_path(:unavail))
    end

    #
    # Deletes 'ghost' Messages from all Folders
    #
    # See ActiveMailbox::Folder#clean_ghosts! for
    # info on 'ghost' voicemails in Asterisk
    #
    def clean_ghosts!(autosort = true)
      folders.each do |name, folder|
        folder.clean_ghosts!(autosort)
      end
    end

    #
    # Deletes Messages older than 30 days from all Folders
    #
    def clean_stale!(autosort = true)
      folders.each do |name, folder|
        folder.clean_stale!(autosort)
      end
    end

    #
    # Path to greeting
    #
    def greeting_path(greeting = :unavail)
      "#{mailbox_path}/#{greeting}.wav"
    end

  private

    #
    # Check if greeting file exists
    #
    def greeting_exists?(greeting = :unavail)
      ValidGreetings.include?(greeting) && File.exist?(greeting_path(greeting))
    end

    #
    # Path to mailbox
    #
    def mailbox_path
      "%s/%s/%s" % [ActiveMailbox::VOICEMAIL_ROOT, @context, @mailbox]
    end

    #
    # These dirs are used by Asterisk and don't contain anything
    # ActiveMailbox is interested in
    #
    def ignore_dirs
      %w[tmp temp unavail]
    end
  end
end
