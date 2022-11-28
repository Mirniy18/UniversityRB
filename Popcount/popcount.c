#include "ruby.h"

static VALUE
rb_popcount(VALUE _, VALUE x) {
    if (RB_TYPE_P(x, T_FIXNUM)) {
        long i = FIX2LONG(x);

        if (i < 0) i = -i;

        return INT2FIX(__builtin_popcountl(i));
    }

    if (RB_TYPE_P(x, T_BIGNUM)) {
        rb_raise(rb_eTypeError, "too big");
    }

    rb_raise(rb_eTypeError, "");
}

void Init_popcount() {
    rb_define_global_function("popcount", rb_popcount, 1);
}
