module Byebug
  #
  # Tests exiting Byebug functionality.
  #
  class QuitTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:
        4:    Object.new
        5:  end
      EOC
    end

    def test_finishes_byebug_if_user_confirms
      QuitCommand.any_instance.expects(:exit!)
      enter 'quit', 'y'
      debug_code(program)
      check_output_includes 'Really quit? (y/n)'
    end

    def test_does_not_quit_if_user_did_not_confirm
      QuitCommand.any_instance.expects(:exit!).never
      enter 'quit', 'n'
      debug_code(program)
      check_output_includes 'Really quit? (y/n)'
    end

    def test_quits_inmediately_if_used_with_bang
      QuitCommand.any_instance.expects(:exit!)
      enter 'quit!'
      debug_code(program)
      check_output_doesnt_include 'Really quit? (y/n)'
    end

    def test_quits_inmediately_if_used_with_unconditionally
      QuitCommand.any_instance.expects(:exit!)
      enter 'quit unconditionally'
      debug_code(program)
      check_output_doesnt_include 'Really quit? (y/n)'
    end

    def test_closes_interface_before_quitting
      QuitCommand.any_instance.stubs(:exit!)
      interface.expects(:close)
      enter 'quit!'
      debug_code(program)
    end

    def test_quits_if_used_with_exit_alias
      QuitCommand.any_instance.expects(:exit!)
      enter 'exit!'
      debug_code(program)
    end
  end
end
