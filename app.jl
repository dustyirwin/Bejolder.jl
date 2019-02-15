using Pkg

Pkg.activate(".")
pkg"instantiate"
pkg"up"
pkg"precompile"

include("./src/Bejolder.jl")

app()
