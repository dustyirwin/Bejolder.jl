function freeze_inputs(inputs::Dict, outputs=Dict())
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
                @async try push!(_results, scan(
                    markets[market],
                    keyword,
                    inputs[market]["category"],
                    inputs[market]["filters"],
                    inputs[market]["max_pages"]))
                catch err; println(upper("error searching $market: ") * err) end
            end # if
        end # for
    end # for

    return _results
end

function get_search_results(inputs::Dict) # frozen or json inputs
    r = Window()
    _results = query_markets(inputs::Dict)
    results_inputs = results["inputs"](inputs["keywords"])

    @async if search["inputs"]["autosave_csv_chk"][] == true
        export_CSV(results_inputs["filename"][], _results)
        @js r alert("Search results saved to CSV file.")
    end

    @async if search["inputs"]["display_results_chk"][] == true
        title(r, results["title"])
        size(r, results["size"][1], results["size"][2])
        body!(r, results["page"](results_inputs, _results))
        results["events"](r, results_inputs, _results)
    end

    return _results
end

search = Dict(
    "title" => "SEARCH ~ bejolder",
    "size" => (800, 525),
    "market_inputs" => (markets::Dict=markets) -> Dict(
        market_name => Dict(
            "enabled" => toggle(false, "$market_name.com"),
            "category" => dropdown(markets[market_name]["categories"]),
            "filters" => dropdown(markets[market_name]["filters"], multiple=true),
            "max_pages" => spinbox(1:10, label="pgs"; value=1),
        ) for market_name in keys(markets)),
    "market_widgets"=> (market_inputs::Dict) -> Dict(market_name => vbox(
            market_inputs[market_name]["enabled"], vskip(0.5em),
            market_inputs[market_name]["category"], vskip(0.5em),
            market_inputs[market_name]["filters"], vskip(0.5em),
            market_inputs[market_name]["max_pages"]) for market_name in keys(market_inputs)),
    "page_inputs" => Dict(
        "keywords" => textbox("Enter search keywords here"),
        "search_btn" => button("SEARCH"),
        "save_json_btn" => button("Save Search"),
        "load_json_btn" => filepicker(label="Load Search"),
        "use_json_chk" => checkbox(false, label="use .json file"),
        "autosave_csv_chk" => checkbox(false, label="autosave results.csv"),
        "display_results_chk" => checkbox(true, label="display results"),
        )
    )

search["market_inputs"] = search["market_inputs"]()

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
    vbox(
        hbox(
            hskip(7em),
            search["inputs"]["search_btn"], hskip(1em),
            search["inputs"]["load_json_btn"], hskip(1em),
            search["inputs"]["save_json_btn"]),
        hbox(
            hskip(7em),
            search["inputs"]["display_results_chk"],
            search["inputs"]["use_json_chk"],
            search["inputs"]["autosave_csv_chk"]),
        )
    )

search["page"] = node(:div, search["page_wdg"])

search["events"] = (w, inputs::Dict=search["inputs"]) ->
    @async while true
        if inputs["search_btn"][] > 0 || inputs["save_json_btn"][] > 0

            # search using json file
            if inputs["use_json_chk"][] == true && inputs["search_btn"][] > 0
                inputs["search_btn"][] = 0

                if occursin(".json", inputs["load_json_btn"][])
                    json_inputs = open(inputs["load_json_btn"][], "r") do f
                        JSON.parse(JSON.read(f, String)) end
                    get_search_results(json_inputs)
                    continue

                else
                    @js w alert("Please select a valid .json search file.")
                    continue
                end
            end

            # search using UI
            if true in [inputs[market]["enabled"][] for market in keys(markets)]

                if inputs["keywords"][] != ""

                    # save search settings
                    if inputs["save_json_btn"][] > 0
                        inputs["save_json_btn"][] = 0

                        filename = inputs["keywords"][] * ".json"
                        open(filename, "w") do f
                            JSON.write(f, json(freeze_inputs(inputs))) end
                        @js w alert("Search settings saved to .json file.")
                        continue end

                    inputs["search_btn"][] = 0
                    get_search_results(freeze_inputs(inputs))
                    continue

                else
                    inputs["search_btn"][] = inputs["save_json_btn"][] = 0
                    @js w alert("Enter a search term.")
                    continue end

            else
                inputs["search_btn"][] = inputs["save_json_btn"][] = 0
                @js w alert("Please select at least one market to query.")
                continue end

        else
            sleep(0.1)
        end
    end # while
