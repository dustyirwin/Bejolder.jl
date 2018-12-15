module Bejolder
    export app

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
    using DataFrames
    using Statistics
    using OnlineStats
    using Plots
    import WebIO: render

    include("./brain.jl")
    include("./eye.jl")
    include("./market.jl")
    include("./user.jl")

    # pages
    include("./pages/login.jl")
    include("./pages/results.jl")
    include("./pages/search.jl")
    include("./pages/tracker.jl")
    include("./pages/dash.jl")

    function update_window(w, page::Dict)
        size(w, page["size"][1], page["size"][2])
        title(w, page["title"])
        body!(w, page["page"])
        page["events"](w)
    end

    function app(page::Dict=login)
        w = Window()
        update_window(w, page)
        return w
    end

end # module
