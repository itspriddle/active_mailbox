require 'optparse'

module ActiveMailbox
  #
  # This class facilites ActiveMailbox's command line functions
  #
  class CLI

    #
    # Invoke the CLI
    #
    def self.run!(argv)
      options = ActiveMailbox::CLI.parse(argv)

      args = [options[:mailbox]]
      args.unshift(options[:context]) if options[:context]

      mailbox = ActiveMailbox::Mailbox.find(*args)

      if options[:arg]
        mailbox.send(options[:command], options[:arg])
      else
        mailbox.send(options[:command])
      end
    end

    #
    # Parse CLI arguments (ARGV)
    #
    def self.parse(argv)
      options = {}

      ::OptionParser.new do |opts|
        opts.banner = "Usage: active_mailbox [OPTION] MAILBOX\n"

        opts.separator ""
        opts.separator "Mailbox Options:"

        opts.on('--context', 'Look for [MAILBOX] in [CONTEXT]') do |context|
          options[:context] = conext
        end

        opts.on('--delete', 'Delete [MAILBOX] and all messages') do
          options[:command] = :delete!
        end

        opts.on('--sort', 'Sort messages in [MAILBOX] (recursive)') do
          options[:command] = :sort!
        end

        opts.separator ""
        opts.separator "Cleanup Options:"

        opts.on('--clean-ghosts', "Cleanup 'ghost' messages") do
          options[:command] = :clean_ghosts!
        end

        opts.on('--clean-stale', 'Cleanup messages older than 30 days') do
          options[:command] = :clean_stale!
        end

        opts.on('--purge', 'Remove all messages, but leave [MAILBOX] folders intact') do
          options[:command] = :purge!
        end

        opts.separator ""
        opts.separator "Greeting Options:"

        opts.on('--delete-temp', 'Delete [MAILBOX]/temp.wav') do
          options[:command] = :delete_temp_greeting!
        end

        opts.on('--delete-unavail', 'Delete [MAILBOX]/unavail.wav') do
          options[:command] = :delete_unavail_greeting!
        end

        opts.on('--delete-busy', 'Delete [MAILBOX]/busy.wav') do
          options[:command] = :delete_busy_greeting!
        end

        opts.separator ""
        opts.separator "General Options:"

        opts.on('-h', '--help', 'Show this message') do
          options[:command] = :help
          puts opts
          exit
        end

        opts.on('-v', '--version', 'Show version') do
          options[:command] = :version
          puts ActiveMailbox::Version
          exit
        end

        begin
          argv = ['-h'] if argv.empty?
          opts.parse!(argv)
          options[:mailbox] = argv.shift
          options
        rescue ::OptionParser::ParseError => err
          STDERR.puts err.message, "\n", opts
          exit(-1)
        end
      end
    end
  end
end
