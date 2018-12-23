function search_to_inactive(filename::String, searches::Dict=searches)
    JLD2.@load filename _search
    searches["inactive"][filename] = _search
end

function rm_search(w::Window, searches::Dict=searches)
    confirm = @js w confirm("Remove the selected Search(s)?")

    if confirm == true
        active_keys = tracker["active"][]
        delete!(searches["active"], active_keys)

        inactive_keys = tracker["inactive"][]
        delete!(searches["inactive"], inactive_keys)

        update(w, tracker)
    end
end

function show_search_info(inputs::Dict)
    for search in merge(searches["active"], searches["inactive"])
        t = Window()
    end
    # code for tracked search info
end

searches = Dict(
    "active"=>OrderedCollections.OrderedDict(),
    "inactive"=>OrderedCollections.OrderedDict()
    )

try
    JLD2.@load "./tmp/_searches.bjd" searches
catch
    println("./tmp/_searches.bjd not found. Using default.")
end

tracker = Dict(
    "title" => "TRACKER ~ bejolder",
    "size" => (1025, 250),
    "inputs" => Dict(
        "active"=>dropdown(searches["active"], label="Active Searches", multiple=true),
        "inactive"=>dropdown(searches["inactive"], label="Inactive Searches", multiple=true),
        "push_right_btn"=>button(">>"),
        "push_left_btn"=>button("<<"),
        "show_info_btn"=>button("Show Search Info(s)"),
        "load_search_btn"=>filepicker("choose .bjs file..."),
        "track_search_btn"=>button("<< Track Search"),
        "save_search_btn"=>button("Save Search(s)"),
        "create_search_btn"=>button("Create Search"),
        "remove_search_btn"=>button("Remove Search(s)"))
    )

tracker["page"] = node(:div,
    hbox(
        hskip(1em), tracker["inputs"]["active"], hskip(1em),
        vbox(vskip(3em),
            tracker["inputs"]["push_right_btn"],
            tracker["inputs"]["push_left_btn"]),
        hskip(1em), tracker["inputs"]["inactive"], hskip(2em),
        vbox(
            hbox(
                tracker["inputs"]["track_search_btn"], hskip(1em),
                tracker["inputs"]["load_search_btn"]),
            hbox(
                tracker["inputs"]["save_search_btn"], hskip(1em),
                tracker["inputs"]["show_info_btn"], hskip(1em),
                tracker["inputs"]["remove_search_btn"]),
            tracker["inputs"]["create_search_btn"]))
    ) # node

tracker["events"] = (w::Window, inputs=tracker["inputs"]) ->
    @async while true  # UI events
        if inputs["track_search_btn"][] != "" && inputs["load_search_btn"][] > 0
            inputs["track_search_btn"][] = 0
            @load inputs["load_search"][] _search
            searches["inactive"][_search.name] = _search
            update_window(w, tracker)
            continue
        elseif inputs["create_search_btn"][] > 0
            inputs["create_search_btn"][] = 0
            s = app(search)
        else
            sleep(0.1)
        end
    end

    @async while true  # Search tracking loop
        @sync for _search in tracker["inputs"]["active"][]
        #    _search, _results = process_search(_search)
        #    JLD2.@save _search.name
        end
        sleep(0.1)
    end
