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
    using Statistics
    using JuliaDB: table
    import WebIO: render

    include("./brain.jl")
    include("./eye.jl")
    include("./market.jl")
    include("./user.jl")

    # app pages
    include("./pages/login.jl")
    include("./pages/results.jl")
    include("./pages/search.jl")

    pages = Dict(
        "search"=>search,
        "login"=>login,
        "results"=>results,
        )

    function update_window(w, p)
        size(w, p["size"][1], p["size"][2])
        title(w, p["title"])
        body!(w, p["page"])
        p["events"](w, p["inputs"])
    end

    function app(pages=pages)
        w = Window()
        update_window(w, pages["search"])
    end

end # module
