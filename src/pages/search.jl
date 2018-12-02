function freeze_inputs(inputs, outputs=Dict())
    outputs["keywords"] = inputs["keywords"][]

    for market in keys(markets)
        outputs[market] = Dict(
            "enabled" => inputs[market]["enabled"][],
            "category" => inputs[market]["category"][],
            "filters" => inputs[market]["filters"][],
            "max_pages" => inputs[market]["max_pages"][])
    end

    return outputs
end

function query_markets(inputs::Dict, _results=[])
    keywords = split(inputs["keywords"], "___")
    i = 0

    @time @sync for keyword in keywords
        i += 1

        if i > 1  # throttle scrapers for 1-2 seconds after 1st query
            sleep(rand(1:0.1:2))
        end

        for market in keys(markets)

            if inputs[market]["enabled"] == true
                @async push!(_results, scan(
                    markets[market],
                    keyword,
                    inputs[market]["category"],
                    inputs[market]["filters"],
                    inputs[market]["max_pages"]))
            end # if
        end # for
    end # for

    return _results
end

search = Dict(
    "title" => "SEARCH ~ beholdia",
    "size" => (800, 475),
    "market_inputs" => (markets) -> Dict(
        market_name => Dict(
            "enabled" => toggle(false, "$market_name.com"),
            "category" => dropdown(markets[market_name]["categories"]),
            "filters" => dropdown(markets[market_name]["filters"], multiple=true),
            "max_pages" => spinbox(1:10, label="pgs"; value=1),
        ) for market_name in keys(markets)),
    "market_widgets"=> (market_inputs) -> Dict(market_name => vbox(
            market_inputs[market_name]["enabled"], vskip(0.5em),
            market_inputs[market_name]["category"], vskip(0.5em),
            market_inputs[market_name]["filters"], vskip(0.5em),
            market_inputs[market_name]["max_pages"]) for market_name in keys(market_inputs)),
    "page_inputs" => Dict(
        "keywords" => textbox("Enter search keywords here"),
        "search_btn" => button("SEARCH"),
        "save_search_btn" => button("Save Search"),
        "load_search_btn" => filepicker(label="Load Search"))
    )

search["market_inputs"] = search["market_inputs"](markets)

search["market_widgets"] = search["market_widgets"](search["market_inputs"])

search["market_widgets_hbox"] = hbox(
    hskip(1.5em), search["market_widgets"]["amazon"],
    hskip(1em), search["market_widgets"]["ebay"],
    hskip(1em), search["market_widgets"]["walmart"],
    hskip(1em), search["market_widgets"]["chewy"])

search["inputs"] = merge(search["market_inputs"], search["page_inputs"])

search["page_wdg"] = vbox(
        search["inputs"]["keywords"],
        search["market_widgets_hbox"],
        vskip(1.5em),
        hbox(
            hskip(5em),
            search["inputs"]["search_btn"],
            hskip(1.25em), search["inputs"]["load_search_btn"],
            hskip(1.25em), search["inputs"]["save_search_btn"]))

search["page"] = node(:div, search["page_wdg"])

search["events"] = (w, inputs) ->
    @async while true
        if inputs["load_search_btn"][] == "" && inputs["search_btn"][] > 0 || inputs["save_search_btn"][] > 0

            if inputs["keywords"][] == ""
                inputs["search_btn"][] = inputs["save_search_btn"][] = 0
                @js w alert("Please enter a search term.")
                continue

            elseif true in [inputs[market]["enabled"][] for market in keys(markets)]

                if inputs["save_search_btn"][] > 0
                    inputs["save_search_btn"][] = 0
                    filename = inputs["keywords"][] * ".json"
                    open(filename, "w") do f
                        JSON.write(f, json(freeze_inputs(inputs))) end
                    @js w alert("Search settings saved to JSON file.")
                    continue
                end

                if inputs["search_btn"][] > 0
                    inputs["search_btn"][] = 0
                    results_inputs = results["inputs"](inputs["keywords"][])
                    _results = query_markets(freeze_inputs(inputs))
                    r = Window(); title(r, results["title"]); size(r, results["size"][1], results["size"][2]);
                    body!(r, results["page"](results_inputs, _results))
                    results["events"](r, results_inputs, _results)
                end

            else
                inputs["search_btn"][] = inputs["save_search_btn"][] = 0
                @js w alert("Please select at least one market to query.")
                continue
            end

        elseif inputs["load_search_btn"][] != "" && inputs["search_btn"][] > 0
            inputs["search_btn"][] = 0
            json_inputs = open(inputs["load_search_btn"][], "r") do f
                JSON.parse(JSON.read(f, String)) end
            export_CSV(json_inputs["keywords"] * "_" * ".csv", query_markets(json_inputs))
            @js w alert("Search results saved to CSV file.")
            continue

        else
            sleep(0.1)
        end
    end # while
