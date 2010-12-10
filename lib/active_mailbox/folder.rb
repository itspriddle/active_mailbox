module ActiveMailbox
  #
  # ActiveMailbox::Folder represents an Asterisk mailbox Folder, such as
  # INBOX, or Old. They contain the actuall messages for a mailbox.
  #
  class Folder

    include Comparable

    attr_reader :path, :mailbox

    attr_accessor :reload_messages

    #
    # Create a new Folder object
    #
    def initialize(path, mailbox)
      unless File.exists?(path)
        raise ActiveMailbox::Errors::FolderNotFound, "#{path} does not exist"
      end
      @mailbox = mailbox
      @path = path
    end

    #
    # Compare base on path
    #
    def <=>(other)
      path <=> other.path
    end

    #
    # An array of Message objects in this folder
    #
    def messages(reload = false)
      if reload or @reload_messages or ! defined?(@messages)
        @messages = []
        Dir.chdir(@path) do
          Dir["*.txt"].each do |txt|
            @messages << Message.new("#{Dir.pwd}/#{txt}", self)
          end
        end
      end
      @messages
    ensure
      @reload_messages = false
    end

    #
    # The name of this folder
    #
    def name
      @name ||= path.split('/').last
    end

    #
    # Returns number of messages in this folder
    #
    def count
      messages.count
    end
    alias :size :count

    #
    # Sort messages in this folder
    #
    # Eg:
    #   Before Sort: msg0002, msg0005, msg0010, msg0020
    #   After Sort:  msg0000, msg0001, msg0002, msg0003
    #
    def sort!
      unless messages.size == messages.last.number + 1

        renamer = lambda do |old_file, new_file|
          %w[wav txt].each do |ext|
            File.rename("#{old_file}.#{ext}", "#{new_file}.#{ext}")
          end
        end

        messages.each_with_index.map do |message, index|
          old_file = message.path
          tmp_file = old_file.sub(/msg[0-9]{4}/, 'temp_msg%04d' % index)
          renamer.call(old_file, tmp_file)
          [old_file, tmp_file]
        end.each do |old_file, tmp_file|
          new_file = tmp_file.sub('temp_msg', 'msg')
          renamer.call(tmp_file, new_file)
        end
      end
    ensure
      @reload_messages = true
    end

    #
    # Destroy all messages/info files in this folder
    #
    def purge!
      Dir.chdir(@path) do
        Dir["*"].each do |file|
          File.unlink(file)
        end
      end
    ensure
      @reload_messages = true
    end

    #
    # Clean all 'ghost' Messages in this Folder
    #
    # A 'ghost' voicemail occurs when the .wav file does not exist.
    # Asterisk sees the info (txt) file and thinks a voicemail exists,
    # then plays nothing as the wav is not found.
    #
    # At the same time, you might run into issues if a wav exists, but
    # not the txt file.
    #
    def clean_ghosts!(autosort = true)
      Dir.chdir(@path) do
        message_list.each do |file|
          txt = "#{Dir.pwd}/#{file}.txt"
          wav = "#{Dir.pwd}/#{file}.wav"

          txt_exists = File.exists?(txt)
          wav_exists = File.exists?(wav)

          unless txt_exists && wav_exists
            File.unlink(txt) if txt_exists
            File.unlink(wav) if wav_exists
          end
        end
      end
      sort! if autosort
    end

    #
    # Destroy Messages in this Folder that are older than 30 days
    #
    def clean_stale!(autosort = true)
      messages.each do |message|
        message.destroy! if message.stale?
      end
      sort! if autosort
    end

    #
    # Destroy this Folder
    #
    def destroy!
      FileUtils.rm_rf(@path)
    end

  private
    #
    # Grabs a list of valid message files in this folder
    #
    def message_list(strip_extension = true)
      Dir['msg[0-9][0-9][0-9][0-9]*'].map do |file|
        if strip_extension
          file.split('.').first
        else
          file
        end
      end.uniq
    end
  end
end
