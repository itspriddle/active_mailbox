require File.dirname(__FILE__) + '/test_helper.rb'

class FolderTest < Test::Unit::TestCase
  context "ActiveMailbox::Folder" do
    setup do
      ActiveMailbox::Fixtures.create!
      @mailbox = ActiveMailbox::Mailbox.find('15183332220')
      @folder  = @mailbox.inbox
    end

    teardown do
      ActiveMailbox::Fixtures.destroy!
    end

    should "raise FolderNotFound with an invalid path" do
      assert_raise ActiveMailbox::Errors::FolderNotFound do
        ActiveMailbox::Folder.new('i am not real!', @mailbox)
      end
    end

    context "instance" do
      should "yield an array of Message objects" do
        assert @folder.messages.is_a?(Array)
        assert @folder.messages.first.is_a?(ActiveMailbox::Message)
      end

      should "destroy itself" do
        path = @folder.path
        @folder.destroy!
        assert File.exists?(path) == false
      end

      should "sort and rename messages by filename" do
        messages = @folder.messages.map(&:name)
        assert messages.size == @folder.size

        ActiveMailbox::Fixtures.simulate_unordered(@folder)
        assert messages.size > @folder.size

        names = messages.map { |m| "msg%04d" % m.match(/([0-9]{4})/)[1].to_i }
        check = (0..messages.size - 1).map { |i| "msg%04d" % i }
        assert_same_elements names, check
      end

      should "clean ghost messages" do
        ActiveMailbox::Fixtures.simulate_ghosts(@folder)
        count = @folder.size
        @folder.clean_ghosts!
        assert count > @folder.size
      end

      should "purge all messages" do
        @folder.purge!
        assert @folder.size == 0
      end

      should "clean stale messages" do
        count = @folder.size
        @folder.clean_stale!
        assert @folder.size < count
      end

      should "be compared to another instance by path" do
        mailbox = ActiveMailbox::Mailbox.find(@mailbox.mailbox)
        folder = ActiveMailbox::Folder.new(@folder.path, mailbox)
        assert folder == @folder
      end
    end
  end
end
