function make_tracked_query(market_name::String, keywords, category, filters, max_pages)
    query_url = markets[market_name]["query_url"](replace(keywords, " "=>"+"), category, filters)
    univar_stats = Series(Mean(),Variance(),Extrema(),Quantile(),Moments(),Sum())
    m = StatLearn(3, .5 * L2DistLoss(), NoPenalty(), SGD(), rate = LearningRate(.6))
    plot_obs = Series(Partition(Mean()), Partition(Extrema()))
    tq = TrackedQuery(market_name, keywords, category, join(filters), max_pages, query_url, univar_stats, m, plot_obs)
    return tq
end

function make_tracked_search(ts_name::String, interval::Hour, inputs::Dict, tqs=[])

    for market_name in [keys(markets)...]
        if inputs[market_name]["enabled"] == true
            push!(tqs, make_tracked_query(
                market_name,
                inputs["keywords"],
                inputs[market_name]["category"],
                inputs[market_name]["filters"],
                inputs[market_name]["max_pages"]))
        end
    end

    return TrackedSearch(ts_name, interval, tqs, now())
end

function process_tracked_search(ts)

    @sync @async for tq in ts.tracked_queries
        r = scan(markets[tq.market], tq.keywords, tq.category, tq.filters, tq.max_pages)
        prices = get_prices(r)["prices"]
        var_vec = (Float64(Month(now()).value), Float64(Day(now()).value), markets[tq.market]["id"])

        fit!(tq.price_stats, prices)
        fit!(tq.plot_obs, prices)
        fit!(tq.price_pred, (var_vec, tq.price_stats.stats[1].μ))
    end

    println("$(ts.name) update complete.")
    return ts
end

function add_tracked_search()
end

function rm_tracked_search()
end

function show_search_info(inputs)
    for ts in merge(tracked_searches["active"], tracked_searches["inactive"])
        
        t = Window()
    end
    # code for tracked search info
end

tracked_searches = OrderedDict(
    "active" => OrderedDict("None"=>"filename"),
    "inactive" => OrderedDict("None"=>"filename"))

tracker = Dict(
    "title" => "TRACKER ~ bejolder",
    "size" => (850, 250),
    "inputs" => Dict(
        "active"=>dropdown(tracked_searches["active"], label="Active Searches", multiple=true),
        "inactive"=>dropdown(tracked_searches["inactive"], label="Inactive Searches", multiple=true),
        "push_right_btn"=>button("⇉"),
        "push_left_btn"=>button("⇇"),
        "show_search_info_btn"=>button("Show Search Info"),
        "load_search"=>filepicker("tracked_search.jld2"),
        "load_search_btn"=>button("Load Search"),
        "export_search"=>button("Export Search"))
    )

tracker["page"] = node(:div,
    hbox(
        hskip(1em), tracker["inputs"]["inactive"],
        vbox(vskip(2em),
            tracker["inputs"]["push_right_btn"],
            tracker["inputs"]["push_left_btn"]),
        hskip(2em), tracker["inputs"]["active"], hskip(2em),
        vbox(
            hbox(
                tracker["inputs"]["load_search_btn"], hskip(1em),
                tracker["inputs"]["load_search"]),
            hbox(
                tracker["inputs"]["export_search"], hskip(1em),
                tracker["inputs"]["show_search_info_btn"]))),
    ) # node

tracker["check_inputs"] = (inputs=tracker["inputs"]) ->
    if inputs["load_search"][] != "" && inputs["load_search_btn"][] > 0
        inputs["load_search_btn"][] = 0
        @load inputs["load_search"][] ts
        active_searches[ts.name] = ts
    end

tracker["events"] = (w) ->
    @async while true
        println("Tracker events started! breaking loop now...")
        break
    end
