using Pkg

Pkg.activate(".")  # reqs Project.toml & Mainfest.toml
# pkg"instantiate"
# pkg"up; precompile"

include("./src/Bejolder.jl")
w = Window()
update_window(w, login)
