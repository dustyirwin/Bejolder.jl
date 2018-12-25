using Pkg
Pkg.activate(".")
#Pkg.instantiate()

include("./src/Bejolder.jl")

app()
