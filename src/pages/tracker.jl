function track_searches(w::Window, inputs=tracker["inputs"])
    @async while true
        if inputs["track_searches"][] == true

            for filename in values(searches["active"])
                JLD2.@load filename _search; _search

                if (now() - _search.runs[end]) > _search.interval
                    _search, _results = process_search(_search)
                    JLD2.@save filename _search
                    println(_search.name * " updated.")
                else
                    println(_search.name, " skipped. Last ran: ", _search.runs[end])
                end
            end

            @async if search["inputs"]["autosave_csv_chk"][] == true
                export_CSV(results_inputs["filename"][], _results)
                @js w alert("Search results saved to .csv file.")
            end

            @async if search["inputs"]["autosave_bjs_chk"][] == true
                save_search(w, _search.name, _search)
                @js w alert("Search object saved to .bjs file.")
            end

        else
            sleep(1)
        end
    end
end

function remove_search(w::Window, inputs::Dict)
    confirm = @js w confirm("Remove the selected Search(s)?")

    if confirm == true
        selected = merge(inputs["inactive"][], inputs["active"][])

        for k in keys(merge(searches["inactive"], searches["active"]))
            try if searches["inactive"][k] in selected
                delete!(searches["inactive"], k) end catch
            try if searches["active"][k] in selected
                delete!(searches["active"], k) end catch end end
        end

        JLD2.@save "./tmp/_searches.bjd" searches
        include("./src/pages/tracker.jl")
        @async update_window(w, tracker)
    end
end

function load_search(w::Window, inputs::Dict)
    JLD2.@load inputs["filename_btn"][] _search
    searches["inactive"][_search.name] = inputs["filename_btn"][]
    JLD2.@save "./tmp/_searches.bjd" searches
    include("./src/pages/tracker.jl")
    @async update_window(w, tracker)
end

function push_right(w::Window, inputs::Dict)
    selected = inputs["inactive"][]
    for k in keys(searches["inactive"])
        if searches["inactive"][k] in selected
            searches["active"][k] = searches["inactive"][k]
            delete!(searches["inactive"], k)
        end
    end

    JLD2.@save "./tmp/_searches.bjd" searches
    include("./src/pages/tracker.jl")
    @async update_window(t, tracker)
end

function push_left(w::Window, inputs::Dict)
    selected = inputs["active"][]
    for k in keys(searches["active"])
        if searches["active"][k] in selected
            searches["inactive"][k] = searches["active"][k]
            delete!(searches["active"], k)
        end
    end

    JLD2.@save "./tmp/_searches.bjd" searches
    include("./src/pages/tracker.jl")
    @async update_window(t, tracker)
end

searches =
    try JLD2.@load "./tmp/_searches.bjd" searches; searches
    catch
        Dict(
            "active"=>OrderedCollections.OrderedDict(),
            "inactive"=>OrderedCollections.OrderedDict())
    end

tracker = Dict(
    "title" => "TRACKER ~ bejolder",
    "size" => (790, 400),
    "inputs" => Dict(
        "push_right_btn"=>button(">>"),
        "push_left_btn"=>button("<<"),
        "show_info_btn"=>button("Show Info(s)"),
        "filename_btn"=>filepicker("choose .bjs file..."),
        "load_search_btn"=>button("^^ Load Search ^^"),
        "create_search_btn"=>button("Create Search"),
        "remove_search_btn"=>button("Remove Search(s)"),
        "active" => dropdown(searches["active"], label="Active Searches", multiple=true),
        "inactive" => dropdown(searches["inactive"], label="Inactive Searches", multiple=true),
        "track_searches" => toggle("TRACK SEARCHES"),
        "keywords" => textbox(""),  # not on UI
        )
    )

tracker["page"] = node(:div,
    vbox(
        hbox(hskip(2em),
            tracker["inputs"]["inactive"], hskip(1em),
            vbox(vskip(3em),
                tracker["inputs"]["push_right_btn"],
                tracker["inputs"]["push_left_btn"]), hskip(1em),
            tracker["inputs"]["active"]),
        vskip(1em),
        hbox(hskip(1em),
            tracker["inputs"]["load_search_btn"], hskip(1em),
            tracker["inputs"]["filename_btn"]),
        hbox(hskip(1em),
            tracker["inputs"]["show_info_btn"], hskip(1em),
            tracker["inputs"]["remove_search_btn"], hskip(1em),
            tracker["inputs"]["create_search_btn"])),
    hbox(
        hskip(1em), tracker["inputs"]["track_searches"])) # node

tracker["events"] = function(w::Window, inputs=tracker["inputs"])
    @async while true  # UI events
        if inputs["load_search_btn"][] > 0
            inputs["load_search_btn"][] = 0

            if inputs["filename_btn"][] == ""  # no file specified error
                @js w alert("No file specified.")
                continue
            else
                try
                    load_search(w, inputs)
                    break # changes UI
                catch err  # invalid file error
                    println(err)
                    @js w alert("Invalid Search file specified. Is this a .bjs file?")
                    continue
            end end

        elseif inputs["create_search_btn"][] > 0
            inputs["create_search_btn"][] = 0
            @async app(search)
            continue

        elseif inputs["remove_search_btn"][] > 0
            inputs["remove_search_btn"][] = 0
            remove_search(w, inputs)
            break # changes UI

        elseif inputs["show_info_btn"][] > 0
            inputs["show_info_btn"][] = 0

            @async for filename in merge(tracker["inputs"]["active"][], tracker["inputs"]["inactive"][])
                JLD2.@load filename _search
                process_results(t, freeze(search["inputs"]), _search)
                continue
            end

        elseif inputs["push_right_btn"][] > 0
            inputs["push_right_btn"][] = 0
            push_right(w, inputs)
            break # changes UI

        elseif inputs["push_left_btn"][] > 0
            inputs["push_left_btn"][] = 0
            push_left(w, inputs)
            break # changes UI

        elseif inputs["track_searches"][] == true
            i = 0  # search counter

            @sync @async for filename in values(searches["active"])
                try
                    JLD2.@load filename _search; search

                    if now() - _search.runs[end] > _search.interval
                        _search, _results = process_search(_search)
                        JLD2.@save filename _search
                        i += 1
                    end
                catch err  # todo: log errors to file
                    println(err)
                end
            end

            if i < 1  # sleep if any searches ran / blocks tracker inputs?
                println("No searches ready. Sleeping..."); sleep(5)
            end

        else
            sleep(0.25)
        end
    end
end
