require File.dirname(__FILE__) + '/test_helper.rb'

class MailboxTest < Test::Unit::TestCase
  context "ActiveMailbox::Mailbox" do
    should "find Mailbox with extension and context" do
      ActiveMailbox::Fixtures.execute! do
        assert ActiveMailbox::Mailbox.find('15183332220')
      end
    end

    should "find Mailbox with extension only" do
      ActiveMailbox::Fixtures.execute! do
        m1 = ActiveMailbox::Mailbox.find('15183332220', '518')
        m2 = ActiveMailbox::Mailbox.find('15183332220')
        assert m1 == m2
      end
    end

    should "raise MailboxNotFound with invalid path" do
      assert_raise ActiveMailbox::Errors::MailboxNotFound do
        ActiveMailbox::Mailbox.find('i certainly', 'dont exist')
      end
    end

    context "instance" do
      setup do
        ActiveMailbox::Fixtures.create!
        @mailbox = ActiveMailbox::Mailbox.find('15183332220', '518')
      end

      teardown do
        ActiveMailbox::Fixtures.destroy!
      end

      should "use method_missing to simulate folder accessors" do
        @mailbox.folders.keys.each do |folder|
          assert_nothing_raised do
            assert @mailbox.send(folder)
          end
          assert @mailbox.send(folder) == @mailbox.folders[folder]
        end

        assert_raise NoMethodError do
          @mailbox.i_dont_exist
        end
      end

      should "yield Folder hash" do
        assert @mailbox.folders.is_a?(Hash)
        @mailbox.folders.each do |key, folder|
          assert folder.is_a?(ActiveMailbox::Folder)
        end
      end

      should "purge all messages in all folders" do
        assert @mailbox.total_messages > 0
        @mailbox.purge!
        @mailbox.folders.each do |name, folder|
          assert folder.messages.empty?
          assert File.exists?(folder.path)
        end
        assert_equal 0, @mailbox.total_messages
      end

      should "destroy itself" do
        @mailbox.destroy!
        assert File.exists?(@mailbox.path) == false
      end

      should "yield a current greeting" do
        assert @mailbox.current_greeting
      end

      should "delete valid greeting" do
        @mailbox.delete_greeting!(:unavail)
        assert File.exists?(@mailbox.greeting_path(:unavail)) == false
        assert_raise ActiveMailbox::Errors::GreetingNotFound do
          @mailbox.delete_greeting!(:i_am_not_real)
        end

        assert @mailbox.delete_greeting!(:unavail) == false
      end

      should "delete temp greeting" do
        @mailbox.delete_temp_greeting!
        assert File.exists?(@mailbox.greeting_path(:temp)) == false
      end

      should "delete unvavail greeting" do
        @mailbox.delete_unavail_greeting!
        assert File.exists?(@mailbox.greeting_path(:unavail)) == false
      end

      should "delete busy greeting" do
        @mailbox.delete_busy_greeting!
        assert File.exists?(@mailbox.greeting_path(:busy)) == false
      end

      should "clean ghost messages in all folders" do
        @mailbox.folders.each do |key, folder|
          ActiveMailbox::Fixtures.simulate_ghosts(folder)
          count = @mailbox.total_messages
          @mailbox.clean_ghosts!
          assert count > @mailbox.total_messages
        end
      end

      should "clean stale messages in all folders" do
        count = @mailbox.total_messages
        @mailbox.clean_stale!
        assert count > @mailbox.total_messages
      end

      should "sort and rename all messages in all folders" do
        @mailbox.folders.each do |key, folder|
          messages = folder.messages.map(&:name)
          assert messages.size == folder.size

          ActiveMailbox::Fixtures.simulate_unordered(folder)
          assert messages.size > folder.size

          names = messages.map { |m| "msg%04d" % m.match(/([0-9]{4})/)[1].to_i }
          check = (0..messages.size - 1).map { |i| "msg%04d" % i }
          assert_same_elements names, check
        end
      end

      should "be compared to another instance based on mailbox number" do
        mailbox = ActiveMailbox::Mailbox.find(@mailbox.mailbox)
        assert mailbox == @mailbox
      end

    end
  end
end
