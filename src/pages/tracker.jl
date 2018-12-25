function rm_search(w::Window, searches::Dict=tracker["searches"])
    confirm = @js w confirm("Remove the selected Search(s)?")

    if confirm == true
        active_keys = searches["active"][]
        delete!(searches["active"], active_keys[1])

        inactive_keys = searches["inactive"][]
        delete!(searches["inactive"], inactive_keys[1])

        JLD2.@save "./tmp/_searches.bjd" searches
        update_window(w, tracker)
    end
end

function show_search_info(inputs::Dict)
    for filename in merge(searches["active"][], searches["inactive"][])
        t = Window()
        JLD2.@load filename _search
        body!(t, render(_search))
    end
    # code for tracked search info
end

function render(_search::Search)
    node(:div,
        "keywords: " * _search.name,)
end

tracker = Dict(
    "searches" =>
        try JLD2.@load "./tmp/_searches.bjd" searches; searches
        catch
            Dict(
                "active"=>OrderedCollections.OrderedDict(),
                "inactive"=>OrderedCollections.OrderedDict())
        end)

_tracker = Dict(
    "title" => "TRACKER ~ bejolder",
    "size" => (790, 360),
    "inputs" => Dict(
        "push_right_btn"=>button(">>"),
        "push_left_btn"=>button("<<"),
        "show_info_btn"=>button("Show Search Info(s)"),
        "load_search_btn"=>filepicker("choose .bjs file..."),
        "track_search_btn"=>button("^^ Track Search ^^"),
        "save_search_btn"=>button("Save Search(s)"),
        "create_search_btn"=>button("Create Search"),
        "remove_search_btn"=>button("Remove Search(s)"),
        "active" => (tracker=tracker) -> dropdown(
            tracker["searches"]["active"], label="ACTIVE SEARCHES", multiple=true),
        "inactive" => (tracker=tracker) -> dropdown(
            tracker["searches"]["inactive"], label="INACTIVE SEARCHES", multiple=true))
    )

tracker = merge(tracker, _tracker)

tracker["page"] = (tracker=tracker) -> node(:div,
    vbox(
        hbox(hskip(2em),
            tracker["inputs"]["inactive"](tracker), hskip(1em),
            vbox(vskip(3em),
                tracker["inputs"]["push_right_btn"],
                tracker["inputs"]["push_left_btn"]), hskip(1em),
            tracker["inputs"]["active"](tracker)),
        hbox(hskip(1em),
            tracker["inputs"]["track_search_btn"], hskip(1em),
            tracker["inputs"]["load_search_btn"]),
        hbox(hskip(1em),
            tracker["inputs"]["save_search_btn"], hskip(1em),
            tracker["inputs"]["show_info_btn"], hskip(1em),
            tracker["inputs"]["remove_search_btn"], hskip(1em),
            tracker["inputs"]["create_search_btn"]))
    ) # node

tracker["events"] = (w::Window, inputs=tracker["inputs"]) ->
    @async while true  # UI events
        if inputs["track_search_btn"][] > 0
            inputs["track_search_btn"][] = 0

            if inputs["load_search_btn"][] == ""  # no file specified error
                @js w alert("No file specified.")
                continue
            else
                try
                    JLD2.@load inputs["load_search_btn"][] _search; _search
                    searches = tracker["searches"]
                    searches["inactive"][_search.name] = inputs["load_search_btn"][]
                    JLD2.@save "./tmp/_searches.bjd" searches
                    @js w alert("Search added to inactive searches.")
                    update_window(w, tracker)

                catch err  # invalid file error
                    println(err)
                    @js w alert("Invalid Search file specified. Is this a .bjs file?")
                    continue
                end
            end

        elseif inputs["create_search_btn"][] > 0
            inputs["create_search_btn"][] = 0
            app(search)
            continue
        else
            sleep(0.1)
        end
    end

function track_searches()
    @async while true
        if length(tracker["inputs"]["active"][]) > 0

            for filename in tracker["inputs"]["active"][]
                JLD2.@load filename _search; _search

                if now() - _search.runs[end] > _search.interval
                    _search, _results = process_search(_search)
                    JLD2.@save filename _search
                    continue
                end
            end

        else
            sleep(1)
        end
    end
end
