search = Dict(
    "title" => "SEARCH ~ bejolder",
    "size" => (800, 575),
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
        "search_btn" => button("RUN SEARCH"),
        "load_file_btn" => filepicker("load file..."),
        "use_file_chk" => checkbox(false, label="use selected file"),
        "autosave_csv_chk" => checkbox(false, label="autoexport .csv data"),
        "display_results_chk" => checkbox(true, label="display results"),
        "autosave_bjs_chk" => checkbox(false, label="autosave .bjs object(s)"))
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
            hskip(2em),
            search["inputs"]["search_btn"], hskip(1em),
            search["inputs"]["load_file_btn"], hskip(1em),
            search["inputs"]["use_file_chk"],),
        hbox(
            hskip(2em),
            search["inputs"]["autosave_bjs_chk"],
            search["inputs"]["autosave_csv_chk"],
            search["inputs"]["display_results_chk"]))
    )

search["page"] = () -> node(:div, search["page_wdg"])

search["events"] = (w::Window, inputs=search["inputs"]) ->
    @async while true
        if inputs["search_btn"][] > 0
            inputs["search_btn"][] = 0

            if inputs["use_file_chk"][] == true
                try
                    JLD2.@load inputs["load_file_btn"][] _search
                    println(inputs["load_file_btn"][] * "file loaded!")
                    inputs["keywords"][] = _search.name
                    process_results(w, freeze_inputs(inputs), _search)
                    continue

                catch err  # invalid file error msg
                    println(err)
                    @js w alert("Please select a valid .bjs or .bjk file.")
                    continue
                end

            elseif true in [inputs[market]["enabled"][] for market in keys(markets)]

                if inputs["keywords"][] != ""
                    _search = make_search(inputs["keywords"][], Hour(24), freeze_inputs(inputs))
                    process_results(w, freeze_inputs(inputs), _search)
                    continue

                else # no search term error msg
                    @js w alert("Enter a search term.")
                    continue
                end

            else # no market selected error msg
                @js w alert("Please select at least one market to query.")
                continue
            end

        else
            sleep(0.1)
        end
    end # while
