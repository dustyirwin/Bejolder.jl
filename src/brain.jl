struct Item
    market::Union{String, Missing}
    id::Union{String, Missing}
    name::Union{String, Missing}
    url::Union{String, Missing}
    sales_price::Union{Dict{DateTime, Any}, Missing}
    shipping::Union{String, Missing}
    imgs::Union{Vector{String}, Missing}
    sold_date::Union{String, Missing}
    description::Union{String, Missing}
    query_url::Union{String, Missing}
end

mutable struct Query
    market::String
    keywords::String
    category::Union{String,Int64}
    filters::String
    max_pages::Int64
    query_url::String
    price::Series
    pred_price_μ::StatLearn
    plot_obs::Series
end

mutable struct Search
    name::String
    interval::Minute
    queries::Vector{Query}
    runs::Array{Any}
end

function app(page=login)
    #WebIO host
    #using Mux
    #webio_serve(page("/", req -> login["page"]))
    w = Window()
    return update_window(w, page)
end

function update_window(w::Window, page::Dict)
    size(w, page["size"][1], page["size"][2])
    title(w, page["title"])
    body!(w, page["page"])
    page["events"](w)
end

function export_CSV(filename::String, _results::Array{Any,1})
    df = DataFrame(
        market = [item.market for item in vcat(_results...)],
        id = [typeof(item.id) != String ? missing : item.id for item in vcat(_results...)],
        name = [typeof(item.name) != String ? missing : replace(item.name, ","=>"") for item in vcat(_results...)],
        sales_price = [typeof(item.sales_price) != Dict{DateTime,Float64} ? missing : collect(item.sales_price)[end][2] for item in vcat(_results...)],
        sold_date = [typeof(item.sold_date) != String ? missing : item.sold_date for item in vcat(_results...)],
        url = [typeof(item.url) != String ? missing : item.url for item in vcat(_results...)],
        query_url = [typeof(item.query_url) != String ? missing : item.query_url for item in vcat(_results...)],)

    CSV.write(filename, df)
end

function save_search(w::Window, inputs::Dict, _search::Search)
    if occursin(".bjs", inputs["load_file_btn"][])
        filename = "./tmp/$(inputs["keywords"][])_$(string(now())[1:10]).bjs"
        JLD2.@save filename _search
        @js w alert("Search saved to .bjs file.")
    elseif occursin(".bjk", inputs["load_file_btn"][])
        @js w alert("Write a bulk search function!")
    else  # invalid file error
        @js w alert("Invalid file selected. It is a .bjs or .bjk file?")
    end
end

function freeze(inputs::Dict, outputs=Dict())
    outputs["keywords"] = inputs["keywords"][]

    for market in keys(markets)
        outputs[market] = Dict(
            "enabled" => inputs[market]["enabled"][],
            "category" => inputs[market]["category"][],
            "filters" => inputs[market]["filters"][],
            "max_pages" => inputs[market]["max_pages"][],
            "keywords" => inputs["keywords"][])
    end
    return outputs
end

function make_query(name::String, keywords::String, category::Union{Int64,String}, filters::Union{String,Array{String,1}}, max_pages::Int64)
    query_url = markets[name]["query_url"](replace(keywords, " "=>"+"), category, filters)
    univariate_stats = Series(Mean(), Variance(), Extrema(), Quantile(), Moments(), Sum())
    m = StatLearn(3, .5 * L2DistLoss(), NoPenalty(), SGD(), rate = LearningRate(.6))
    plot_obs = Series(Partition(Mean()), Partition(Extrema()))
    return Query(name, keywords, category, join(filters), max_pages, query_url, univariate_stats, m, plot_obs)
end

function make_search(search_name::String, interval::Minute, inputs::Dict, queries=[]) # frozen or json inputs

    for market_name in [keys(markets)...]
        if inputs[market_name]["enabled"] == true
            push!(queries, make_query(
                market_name,
                inputs[market_name]["keywords"],
                inputs[market_name]["category"],
                inputs[market_name]["filters"],
                inputs[market_name]["max_pages"]))
        end
    end

    return Search(search_name, interval, queries, [])
end

function process_search(_search::Search, _results=[])
    @sync @async for q in _search.queries
        r = scan(markets[q.market], q.keywords, q.category, q.filters, q.max_pages)
        push!(_results, r)

        prices = get_prices(r)["prices"]
        var_vec = (Float64(Month(now()).value), Float64(Day(now()).value), markets[q.market]["id"])

        fit!(q.price, prices)
        fit!(q.plot_obs, prices)
        fit!(q.pred_price_μ, (var_vec, q.price.stats[1].μ))
    end

    push!(_search.runs, now())
    println("$(_search.name) update complete.")
    return _search, _results
end

function process_results(w::Window, inputs::Dict, _search=nothing) # frozen inputs or search
    results_inputs = results["inputs"](inputs["keywords"])

    if _search == nothing
        _search = make_search(inputs["keywords"], Minute(results["inputs"]("")["search_interval"][]), inputs)
        _search, _results = process_search(_search)
    else
        _search, _results = process_search(_search)
    end

    @async begin
        r = Window()
        title(r, results["title"])
        size(r, results["size"][1], results["size"][2])
        body!(r, results["page"](results_inputs, _results, _search))
        results["events"](r, results_inputs, _results, _search)
    end

    return _search, _results
end
