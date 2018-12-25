using Pkg
Pkg.activate(".")
#Pkg.instantiate()

include("./src/Bejolder.jl")

#Blink window
app()

#WebIO host
# something else
