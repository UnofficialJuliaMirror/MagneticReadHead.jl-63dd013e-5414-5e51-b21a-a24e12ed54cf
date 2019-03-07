module MagneticReadHead

using Base: invokelatest
using Cassette
using MacroTools
using Mocking
using OrderedCollections

using CodeTracking
# We don't use Revise, but if it isn't loaded CodeTracking has issues
using Revise: Revise

export set_breakpoint, rm_breakpoint, @iron_debug


include("utils.jl")
include("inner_repl.jl")
include("breakpoints.jl")
include("break_action.jl")
include("locate.jl")

struct UserAbortedException <: Exception end

mutable struct MagneticMetadata
    eval_module::Module
    do_at_next_break_start::Any
    stepping_mode::Bool
end
MagneticMetadata(eval_module) = MagneticMetadata(eval_module, ()->nothing, false)

macro iron_debug(body)
    quote
        ctx = Cassette.disablehooks(MagneticCtx(;metadata=MagneticMetadata($(__module__))))
        try
            Cassette.recurse(ctx, ()->$(esc(body)))
        catch err
            @show err
            err isa UserAbortedException || rethrow()
            nothing
        finally
            disengage_stepping_mode!(ctx)
        end

    end
end

end # module
