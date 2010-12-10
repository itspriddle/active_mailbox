require 'time'

module ActiveMailbox
  #
  # The ActiveMailbox::Message class represents an Asterisk voicemail
  #
  class Message
    #
    # Maximum age before a Message is considered stale (30 days)
    #
    MaximumAge = 2592000

    include Comparable

    #
    # Values from Asterisk's message info file (eg: msg0001.txt)
    # that are used by this class
    #
    InfoFileKeys = %w[callerid origdate duration]

    attr_reader :folder

    def initialize(info_file, folder)
      unless File.exists?(info_file)
        raise ActiveMailbox::Errors::MessageNotFound, "#{info_file} does not exist"
      end
      @folder    = folder
      @info_file = info_file
      parse_data!
    end

    #
    # The name of this message (ex: msg0001)
    #
    def name
      @name ||= path.split('/').last
    end

    #
    # The number pulled from name
    #
    def number
      @number ||= (num = name.match(/([0-9]{4})$/) and num[1].to_i)
    end

    #
    # Compare messages by the number in the name
    #
    def <=>(other)
      number <=> other.number
    end

    #
    # Destroy this Message's wav and txt files
    #
    def destroy!
      [txt, wav].each do |file|
        File.unlink(file)
      end
    ensure
      @folder.reload_messages = true
    end

    #
    # The time the Message was left
    #
    def timestamp
      @timestamp ||= Time.parse(@origdate)
    end

    #
    # The caller's phone number (from CallerID)
    #
    def callerid_number
      @callerid_number ||= @callerid.gsub(/.*\<(.*)\>/, '\1')
    end

    #
    # The caller's name (from CallerID)
    #
    def callerid_name
      @callerid_name ||= @callerid.gsub(/(.*)\s*\<.*\>/, '\1').strip
    end

    #
    # The duration of this Message (in seconds)
    #
    def duration
      @duration
    end

    #
    # The file path to this Message's wav file
    #
    def wav
      @wav ||= @info_file.sub(/txt$/, 'wav')
    end

    #
    # The file path to this Message's txt file
    #
    def txt
      @info_file
    end

    #
    # Returns msgXXXX
    #
    def path
      @msg ||= txt.sub('.txt', '')
    end

    #
    # Checks if this message is stale
    #
    def stale?
      @stale ||= Time.now.to_i - timestamp.to_i > MaximumAge
    end

  private

    def data #:nodoc:
      @data ||= File.read(@info_file)
    end

    def parse_data! #:nodoc:
      data.lines.each do |line|
        key, value = line.split('=')
        if InfoFileKeys.include?(key)
          instance_variable_set("@#{key}", value.chomp)
        end
      end
    end

  end
end
