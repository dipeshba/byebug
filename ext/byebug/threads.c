#include <byebug.h>

/* Threads table class */
static VALUE cThreadsTable;

static int
t_tbl_mark_keyvalue(st_data_t key, st_data_t value, st_data_t tbl)
{
  UNUSED(tbl);

  rb_gc_mark((VALUE) key);

  if (!value)
    return ST_CONTINUE;

  rb_gc_mark((VALUE) value);

  return ST_CONTINUE;
}

static void
t_tbl_mark(void *data)
{
  threads_table_t *t_tbl = (threads_table_t *) data;
  st_table *tbl = t_tbl->tbl;

  st_foreach(tbl, t_tbl_mark_keyvalue, (st_data_t) tbl);
}

static void
t_tbl_free(void *data)
{
  threads_table_t *t_tbl = (threads_table_t *) data;

  st_free_table(t_tbl->tbl);
  xfree(t_tbl);
}

/*
 *  Creates a numeric hash whose keys are the currently active threads and
 *  whose values are their associated contexts.
 */
VALUE
create_threads_table(void)
{
  threads_table_t *t_tbl;

  t_tbl = ALLOC(threads_table_t);
  t_tbl->tbl = st_init_numtable();
  return Data_Wrap_Struct(cThreadsTable, t_tbl_mark, t_tbl_free, t_tbl);
}

/*
 *  Checks a single entry in the threads table.
 *
 *  If it has no associated context or the key doesn't correspond to a living
 *  thread, the entry is removed from the thread's list.
 */
static int
check_thread_i(st_data_t key, st_data_t value, st_data_t data)
{
  UNUSED(data);

  if (!value)
    return ST_DELETE;

  if (!is_living_thread((VALUE) key))
    return ST_DELETE;

  return ST_CONTINUE;
}

/*
 *  Checks whether a thread is either in the running or sleeping state.
 */
int
is_living_thread(VALUE thread)
{
  VALUE status = rb_funcall(thread, rb_intern("status"), 0);

  if (NIL_P(status) || status == Qfalse)
    return 0;

  if (rb_str_cmp(status, rb_str_new2("run")) == 0
      || rb_str_cmp(status, rb_str_new2("sleep")) == 0)
    return 1;

  return 0;
}

/*
 *  Checks threads table for dead/finished threads.
 */
void
check_threads_table(void)
{
  threads_table_t *t_tbl;

  Data_Get_Struct(threads, threads_table_t, t_tbl);
  st_foreach(t_tbl->tbl, check_thread_i, 0);
}

/*
 * Looks up a context in the threads table. If not present, it creates it.
 */
void
thread_context_lookup(VALUE thread, VALUE * context)
{
  threads_table_t *t_tbl;

  Data_Get_Struct(threads, threads_table_t, t_tbl);

  if (!st_lookup(t_tbl->tbl, thread, context) || !*context)
  {
    *context = context_create(thread);
    st_insert(t_tbl->tbl, thread, *context);
  }
}

/*
 * Holds thread execution while another thread is active.
 *
 * Thanks to this, all threads are "frozen" while the user is typing commands.
 */
void
halt_while_other_thread_is_active(debug_context_t * dc)
{
  while ((locker != Qnil && locker != rb_thread_current())
         || CTX_FL_TEST(dc, CTX_FL_SUSPEND))
  {
    add_to_locked(rb_thread_current());
    rb_thread_stop();

    if (CTX_FL_TEST(dc, CTX_FL_SUSPEND))
      CTX_FL_SET(dc, CTX_FL_WAS_RUNNING);
  }
}

/*
 *
 *    Document-class: ThreadsTable
 *
 *    == Sumary
 *
 *    Hash table holding currently active threads and their associated contexts
 */
void
Init_threads_table(VALUE mByebug)
{
  cThreadsTable = rb_define_class_under(mByebug, "ThreadsTable", rb_cObject);
}
