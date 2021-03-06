module Byebug
  #
  # Tests entering IRB from within Byebug.
  #
  class IrbTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:
        4:    a = 2
        5:    a + 4
        6:  end
      EOC
    end

    def setup
      interface.stubs(:kind_of?).with(LocalInterface).returns(true)

      super
    end

    def test_irb_command_starts_an_irb_session
      IrbCommand.any_instance.expects(:execute)

      enter 'irb'
      debug_code(program)
    end

    def test_autoirb_calls_irb_automatically_after_every_stop
      IrbCommand.any_instance.expects(:execute)

      enter 'set autoirb', 'cont 5'
      debug_code(program)
    end
  end
end
