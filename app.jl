include("./src/Bejolder.jl")

Bejolder.app(Bejolder.search)

# debugging

f_ins = Bejolder.freeze_inputs(Bejolder.search["inputs"])
_results = Bejolder.query_markets(f_ins)
Bejolder.get_search_results(f_ins)
