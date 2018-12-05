Base.@ccallable function julia_main(ARGS::Vector{String})::Cint # binary app
    return Bejolder.app()
end

include("./src/Bejolder.jl")

app = Bejolder.app("search") # julia app

Bejolder.search["inputs"]["autosave_csv_chk"][]
Bejolder.search["inputs"]["display_results_chk"][]
r = Bejolder.query_markets(Bejolder.freeze_inputs(Bejolder.search["inputs"]))
Bejolder.get_search_results(app, Bejolder.freeze_inputs(Bejolder.search["inputs"]))
