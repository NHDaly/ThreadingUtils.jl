module ThreadingUtils

import Dates
using Base.Threads: Atomic, @spawn, Condition
using Base: Semaphore, acquire, release, wait
using Dates: Period

export stop_periodic_task!, @spawn_interactive_periodic_task

"""
    PeriodicTask

This structure is a wrapper around background periodic Task and can be used to inspect the
state of the task itself and to safely terminate the background periodic task by signalling
via `should_terminate`.
"""
struct PeriodicTask
    # Name of the periodic task. Attached to error logs for debuggability.
    name::String

    # Specifies how often the underlying periodic task should be run.
    period::Period

    # The Timer used to run the task periodically.
    timer::Timer

    # When set to true, the underlying periodic task will terminate before next
    # iteration.
    should_terminate::Atomic{Bool}

    # The underlying periodic task itself.
    task::Task
end

macro spawn_interactive_periodic_task(name, period, expr)
    return quote
        n = $(esc(name))
        p = $(esc(period))
        timer = Timer(p; interval = p)
        should_terminate = Atomic{Bool}(false)
        # With `:interactive`, this task will run on a thread from the interactive
        # thread pool.
        task = @spawn :interactive begin
            @info "Scheduled sticky periodic task $(n)"
            while !should_terminate[]
                try
                    wait(timer)
                    $(esc(expr))
                catch err
                    if !isa(err, EOFError)
                        @error "$(n): sticky periodic task failed"
                    end
                end
            end
        end
        _pt = PeriodicTask(n, p, timer, should_terminate, task)
        atexit() do
            stop_periodic_task!(_pt)
        end
        _pt
    end
end

"""
    stop_periodic_task!(task::PeriodicTask)

Triggers termination of the periodic task.
"""
function stop_periodic_task!(pt::PeriodicTask)
    pt.should_terminate[] = true
    close(pt.timer)
    wait(pt.task)
    return pt
end

# Reflection methods for the inner ::Task struct.
Base.istaskdone(t::PeriodicTask) = istaskdone(t.task)
Base.istaskfailed(t::PeriodicTask) = istaskfailed(t.task)
Base.istaskstarted(t::PeriodicTask) = istaskstarted(t.task)


end # module
