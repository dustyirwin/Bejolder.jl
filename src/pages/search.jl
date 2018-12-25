search = Dict(
    "title" => "SEARCH ~ bejolder",
    "size" => (850, 575),
    "market_inputs" => (markets::Dict) -> Dict(
        market_name => Dict(
            "enabled" => toggle(false, uppercase(market_name)),
            "category" => dropdown(markets[market_name]["categories"]),
            "filters" => dropdown(markets[market_name]["filters"], multiple=true),
            "max_pages" => spinbox(1:10, label="pgs"; value=1),
            ) for market_name in keys(markets)),
    "market_widgets"=> (market_inputs::Dict) -> Dict(
        market_name => vbox(
            market_inputs[market_name]["enabled"], vskip(0.5em),
            market_inputs[market_name]["category"], vskip(0.5em),
            market_inputs[market_name]["filters"], vskip(0.5em),
            market_inputs[market_name]["max_pages"]) for market_name in keys(market_inputs)),
    "page_inputs" => Dict(
        "keywords" => textbox("Enter search keywords here"),
        "search_btn" => button("SEARCH"),
        "load_search_btn" => filepicker("choose a .bjs file..."),
        "use_file_chk" => checkbox(false, label="use .bjs file"),
        "autosave_csv_chk" => checkbox(false, label="autosave .csv"),
        "display_results_chk" => checkbox(true, label="display results"))
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
    vbox(
        hbox(
            hskip(6em),
            search["inputs"]["search_btn"], hskip(1em),
            search["inputs"]["load_search_btn"], hskip(1em)),
        hbox(
            hskip(6em),
            search["inputs"]["use_file_chk"],
            search["inputs"]["autosave_csv_chk"],
            search["inputs"]["display_results_chk"])
    ))

search["page"] = () -> node(:div, search["page_wdg"])

search["events"] = (w::Window, inputs=search["inputs"]) ->
    @async while true
        if inputs["search_btn"][] > 0
            inputs["search_btn"][] = 0

            if inputs["use_file_chk"][] == true
                try
                    JLD2.@load inputs["load_search_btn"][] _search
                    println("$(inputs["load_search_btn"][]) file loaded!")
                    inputs["keywords"][] = _search.name
                    process_results(w, freeze_inputs(inputs), _search)
                    continue

                catch err
                    println(err)
                    @js w alert("Please select a valid .bjs file.")
                    continue
                end

            # proceed using UI inputs
            elseif true in [inputs[market]["enabled"][] for market in keys(markets)]

                if inputs["keywords"][] != ""
                    _search = make_search(inputs["keywords"][], Hour(24), freeze_inputs(inputs))

                    if inputs["save_search_btn"][] > 0
                        inputs["save_search_btn"][] = 0
                        filename = "./tmp/" * inputs["keywords"][] * "_$(string(now())[1:10])" * ".bjs"
                        JLD2.@save filename _search
                        @js w alert("Search saved to .bjs file.")
                        continue
                    end
                    if inputs["search_btn"][] > 0
                        inputs["search_btn"][] = 0
                        process_results(w, freeze_inputs(inputs), _search)
                        continue
                    end

                else # no search term error msg
                    inputs["search_btn"][] = inputs["save_search_btn"][] = 0
                    @js w alert("Enter a search term.")
                    continue
                end

            else # no market selected error msg
                inputs["search_btn"][] = inputs["save_search_btn"][] = 0
                @js w alert("Please select at least one market to query.")
                continue
            end

        else
            sleep(0.1)
        end
    end # while
