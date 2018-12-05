Base.@ccallable function julia_main(ARGS::Vector{String})::Cint # binary app
    return Bejolder.app()
end

include("./src/Bejolder.jl")

app = Bejolder.app() # julia app

# debugging
Bejolder.search["inputs"]["autosave_csv_chk"][]
Bejolder.search["inputs"]["display_results_chk"][]
r = Bejolder.query_markets(Bejolder.freeze_inputs(Bejolder.search["inputs"]))
Bejolder.process_results(app, Bejolder.search["inputs"], r)
