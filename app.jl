using Pkg

# pkg"instantiate"
# pkg"up; precompile"

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    Pkg.activate(".")  # reqs Project.toml & Mainfest.toml
    include("./src/Bejolder.jl")

    w = Window()
    update_window(w, login)
    return 0
end
