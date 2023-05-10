@info "Pointer of atexit_hooks: $(Base.pointer_from_objref(Base.atexit_hooks))"
#include("ThreadingUtils_tests.jl")

using ReTestItems, ThreadingUtils
runtests(ThreadingUtils, logs=:eager)
