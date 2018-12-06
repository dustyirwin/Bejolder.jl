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
    using DataFrames
    using Statistics
    import WebIO: render

    include("./brain.jl")
    include("./eye.jl")
    include("./market.jl")
    include("./user.jl")

    # app pages
    include("./pages/login.jl")
    include("./pages/results.jl")
    include("./pages/search.jl")

    function update_window(w::Window, p::Dict)
        size(w, p["size"][1], p["size"][2])
        title(w, p["title"])
        body!(w, p["page"])
        p["events"](w, p["inputs"])
    end

    function app(page::Dict=login)
        w = Window()
        update_window(w, page)
    end

end # module
