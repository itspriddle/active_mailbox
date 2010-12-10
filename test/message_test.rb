require 'test_helper'

class MessageTest < Test::Unit::TestCase
  context "ActiveMailbox::Message" do
    setup do
      ActiveMailbox::Fixtures.create!
      @mailbox = ActiveMailbox::Mailbox.find('15183332220', '518')
      @message = @mailbox.inbox.messages.first
    end

    teardown do
      ActiveMailbox::Fixtures.destroy!
    end

    should "raise MessageNotFound initializing with invalid info file path" do
      assert_raise ActiveMailbox::Errors::MessageNotFound do
        ActiveMailbox::Message.new('i dont exist', @mailbox)
      end
    end

    context "instance" do
      should "destroy itself" do
        wav = @message.wav
        txt = @message.txt

        assert @message.destroy!
        assert File.exists?(wav) == false
        assert File.exists?(txt) == false
      end

      should "yield attributes" do
        [:timestamp, :duration, :callerid_number, :callerid_name, :name, :path].each do |key|
          assert @message.send(key).nil? == false
        end
      end

      should "be stale if older than MaximumAge" do
        # last fixture message is older than MaximumAge
        assert @mailbox.inbox.messages.last.stale?
      end

      should "be compared based on message number" do
        m1 = @mailbox.inbox.messages[0]
        m2 = @mailbox.inbox.messages[1]
        assert m1 < m2
      end

    end
  end
end
