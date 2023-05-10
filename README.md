# Reproducer for Julia GC Corruption / Segfault bug

This small reproducer workload, a package called ThreadingUtils, seems to be enough to
reliably reproduce a memory corruption in Julia, leading to a segfault or a GC Corruption.

See the julia issue for more info.

The error can be reproduced like this:
```bash
~/src/julia/julia --project=. -E 'using Pkg; for _ in 1:100; Pkg.test("ThreadingUtils", julia_args=["-t4,1", "--gcthreads=1"]); end'
```
which seems to fail in around 1/30 runs for me on macOS.

Or like this:
```julia
julia> using ReTestItems; for _ in 1:100; ReTestItems.runtests("packages/ThreadingUtils/test", name="@spawn_interactive_periodic_task"); end
```
which runs a bit faster, and also seems to fail in around 1/10 - 1/30 runs.
