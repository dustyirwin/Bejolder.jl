include("./src/Bejolder.jl")

Bejolder.app() # julia app

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint # binary app
    return Bejolder.app()
end
