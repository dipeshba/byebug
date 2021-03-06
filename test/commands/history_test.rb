module Byebug
  #
  # Tests Byebug's command line history.
  #
  class HistoryTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:
        4:    a = 2
        5:    a + 3
        6:  end
      EOC
    end

    def test_history_displays_latest_records_from_readline_history
      enter 'show', 'history'
      debug_code(program)
      check_output_includes('1  show', '2  history')
    end

    def test_history_n_displays_whole_history_if_n_is_bigger_than_history_size
      enter 'show', 'history 3'
      debug_code(program)

      check_output_includes('1  show', '2  history 3')
    end

    def test_history_n_displays_lastest_n_records_from_readline_history
      enter 'show width', 'show autolist', 'history 2'
      debug_code(program)

      check_output_includes('2  show autolist', '3  history 2')
    end

    def test_history_does_not_save_empty_commands
      enter 'show', 'show width', '', 'history 3'
      debug_code(program)

      check_output_includes('1  show', '2  show width', '3  history 3')
    end

    def test_history_does_not_save_duplicated_consecutive_commands
      enter 'show', 'show width', 'show width', 'history 3'
      debug_code(program)

      check_output_includes('1  show', '2  show width', '3  history 3')
    end

    def test_cmds_from_previous_repls_are_remembered_if_autosave_enabled
      enter 'set autosave', 'next', 'history 2'
      debug_code(program)

      check_output_includes('2  next', '3  history 2')
    end

    def test_cmds_from_previous_repls_are_not_remembered_if_autosave_disabled
      enter 'set noautosave', 'next', 'history 2'
      debug_code(program)

      check_output_includes('1  history 2')
    end
  end
end
