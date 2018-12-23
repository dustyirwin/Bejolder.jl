using Pkg
Pkg.activate(".")
#Pkg.instantiate()

include("./src/Bejolder.jl")

#if Blink do
Bejolder.app()

#if WebIO do
#something else
