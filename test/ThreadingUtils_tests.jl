@testitem "@spawn_interactive_periodic_task" begin
    using Dates

    #@info ENV["JULIA_NUM_THREADS"]
    @info Threads.nthreadpools()
    @info Threads.nthreads()
    tlock = ReentrantLock()
    scheduled_at = Dict{Int,Symbol}()
    tasks = Dict{Int,ThreadingUtils.PeriodicTask}()
    task_executed = Dict{Int,Int}()
    Threads.@threads :static for i in 1:Threads.nthreads()  # 4,1 <-- 5
        @info "Spawning T-$i, on thread $(Threads.threadid())"
        t = ThreadingUtils.@spawn_interactive_periodic_task "T-$i" Dates.Millisecond(1000) begin
            #@info "Running T-$i"
            @lock tlock begin
                scheduled_at[i] = Threads.threadpool()
                task_executed[i] = 1
            end
        end
        @lock tlock tasks[i] = t
    end
    # wait for all sticky tasks to get executed and inserted into tasks dict
    while true
        ready = @lock tlock sum(values(task_executed)) == length(tasks) == Threads.nthreads()
        ready && break
        sleep(0.05)
    end
    for t in values(tasks)
        ThreadingUtils.stop_periodic_task!(t)   # Note: also waits for t.task
    end
    @testset "Task $i" for i in 1:Threads.nthreads()
        @test scheduled_at[i] == :interactive
    end
end
