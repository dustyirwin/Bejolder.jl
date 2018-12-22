struct Item
    market::Union{String,Missing}
    id::Union{String,Nothing}
    name::Union{String,Nothing}
    url::Union{String,Nothing}
    sales_price::Union{Dict{DateTime, Float64},Nothing}
    shipping::Union{String,Nothing}
    imgs::Union{Vector{String},Nothing}
    sold_date::Union{String,Nothing}
    description::Union{String,Nothing}
    query_url::Union{String,Nothing}
end

struct Query
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

struct Search
    name::String
    interval::Hour
    queries::Vector{Query}
    runs::Array{Any}
end

function validate_user(w)
    if login["inputs"]["login_btn"][] > 0
        login["inputs"]["login_btn"][] = 0

        if login["inputs"]["username"][] in keys(users) && login["inputs"]["password"][] == users[login["inputs"]["username"][]]["password"]
            update_window(w, search)
            return true
        else
            @js w alert("Incorrect username or password. Try again.")
            return false
        end
    end
end

function get_prices(items, stats=Dict())
    stats["prices"] = [
        collect(item.sales_price)[end][2] for item in items if item.sales_price != nothing && collect(item.sales_price)[end][2] > 0 ]
    stats["render"] = "valid item count: $(length(stats["prices"])) mean: \$$(round(mean(stats["prices"]))) std dev: \$$(round(std(stats["prices"])))"
    return stats
end

function export_CSV(filename::String, _results)
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

function freeze_inputs(inputs::Dict, outputs=Dict())
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

function make_query(name::String, keywords::String, category, filters, max_pages)
    query_url = markets[name]["query_url"](replace(keywords, " "=>"+"), category, filters)
    univariate_stats = Series(Mean(),Variance(),Extrema(),Quantile(),Moments(),Sum())
    m = StatLearn(3, .5 * L2DistLoss(), NoPenalty(), SGD(), rate = LearningRate(.6))
    plot_obs = Series(Partition(Mean()), Partition(Extrema()))
    return Query(name, keywords, category, join(filters), max_pages, query_url, univariate_stats, m, plot_obs)
end

function make_search(search_name::String, interval::Hour, inputs::Dict, queries=[]) # frozen or json inputs

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

function process_results(w, inputs::Dict, _search=nothing) # frozen inputs or search
    results_inputs = results["inputs"](inputs["keywords"])

    if _search == nothing
        _search = make_search(inputs["keywords"], Hour(1), inputs)
        _search, _results = process_search(_search)
    else
        _search, _results = process_search(_search)
    end

    @async if search["inputs"]["autosave_csv_chk"][] == true
        export_CSV(results_inputs["filename"][], _results)
        @js w alert("Search results saved to CSV file.")
    end

    @async if search["inputs"]["display_results_chk"][] == true
        r = Window()
        title(r, results["title"])
        size(r, results["size"][1], results["size"][2])
        body!(r, results["page"](results_inputs, _results))
        results["events"](r, results_inputs, _results)
    end
end
