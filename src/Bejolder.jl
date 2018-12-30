# deps
using Dates
using HTTP
using Gumbo
using Cascadia
using Blink
using Interact
using WebIO
using JSON
using CSV
using JLD2
using Plots
using DataFrames
using Statistics
using OnlineStats
using OrderedCollections
import WebIO: render

include("./brain.jl")
include("./eyes.jl")
include("./markets.jl")
include("./users.jl")

# pages
include("./pages/login.jl")
include("./pages/results.jl")
include("./pages/search.jl")
include("./pages/tracker.jl")
