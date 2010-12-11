require 'rubygems'
require 'test/unit'
require 'turn'
require 'shoulda'
require 'fileutils'
require 'tmpdir'

# Set Asterisk's voicemail path so tests don't clobber a production system
ENV['ASTERISK_VOICEMAIL_ROOT'] = File.join(Dir::tmpdir, "active_mailbox_test_#{Time.now.to_i}")

require 'active_mailbox'

module ActiveMailbox::Fixtures
  extend self

  BASE_DIR = ENV['ASTERISK_VOICEMAIL_ROOT']

  def simulate_ghosts(folder)
    [2, 4, 0, 5].map do |i|
      message = folder.messages[i]
      File.unlink(message.wav)
    end
  end

  def simulate_unordered(folder)
    [2, 4, 0, 5].map do |i|
      folder.messages[i]
    end.each(&:destroy!)
  end

  def mailbox
    File.join(BASE_DIR, '518', '15183332220')
  end

  def inbox
    File.join(mailbox, 'INBOX')
  end

  def old
    File.join(mailbox, 'Old')
  end

  def info_template(date)
    template = %{;
      ; Message Information file
      ;
      [message]
      origmailbox=15183332220
      context=incoming
      macrocontext=
      exten=15183332220
      priority=6
      callerchan=SIP/16.26.15.146-00c811d0
      callerid="Joshua Priddle" <15183332220>
      origdate=#{date}
      origtime=1244496482
      category=
      duration=0}.gsub(/^      /, '')
  end

  def execute!(&block)
    create!
    yield
    destroy!
  end

  def destroy!
    FileUtils.rm_rf(BASE_DIR) if File.exists?(BASE_DIR)
  end

  def create!
    FileUtils.mkdir_p(mailbox)
    FileUtils.touch(File.join(mailbox, 'unavail.wav'))
    FileUtils.touch(File.join(mailbox, 'temp.wav'))
    FileUtils.touch(File.join(mailbox, 'busy.wav'))

    [inbox, old].each do |dir|
      FileUtils.mkdir_p(dir)
      Dir.chdir(dir) do
        0.upto(10) do |i|
          msg = "msg%04d" % i
          wav = "#{msg}.wav"
          txt = "#{msg}.txt"

          FileUtils.touch(wav)

          date = Time.now - (60 * 60 * 24 * (4 * (i + 1)))

          File.open(txt, "w") do |f|
            f.puts info_template(date)
          end

        end
      end
    end
  end
end
