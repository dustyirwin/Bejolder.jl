function remove_search(w::Window, inputs::Dict)
    confirm = @js w confirm("Remove the selected Search(s)?")

    if confirm == true
        selected = merge(inputs["inactive"][], inputs["active"][])
        for k in keys(searches["inactive"])
            try if searches["inactive"][k] in selected
                delete!(searches["inactive"], k) end catch
            try if searches["active"][k] in selected
                delete!(searches["active"], k) end catch end end
        end

        JLD2.@save "./tmp/_searches.bjd" searches
        include("./src/pages/tracker.jl")
        body!(t, tracker["page"]())
    end
end

function add_search(w::Window, inputs::Dict)
    JLD2.@load inputs["load_search_btn"][] _search; _search
    searches["inactive"][_search.name] = inputs["load_search_btn"][]
    JLD2.@save "./tmp/_searches.bjd" searches
    include("./src/pages/tracker.jl")
    body!(t, tracker["page"]())
end

function show_info(w::Window, inputs::Dict)
    @async for filename in values(merge(searches["active"][], searches["inactive"][]))
        t = Window()
        JLD2.@load filename _search
        body!(t, render(_search))
    end
end

function push_right(w::Window, inputs::Dict)
    selected = inputs["inactive"][]

    for k in keys(searches["inactive"])
        try if searches["inactive"][k] in selected
            searches["active"][k] = searches["inactive"][k]
            delete!(searches["inactive"], k) end
        catch end
    end

    include("./src/pages/tracker.jl")
    body!(t, tracker["page"]())
end

function push_left(w::Window, inputs=tracker["inputs"])
    "mirror push right"
end

function render(_search::Search)
    node(:div,
        "keywords: " * _search.name,)
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
        "show_info_btn"=>button("Show Search Info(s)"),
        "load_search_btn"=>filepicker("choose .bjs file..."),
        "track_search_btn"=>button("^^ Track Search ^^"),
        "save_search_btn"=>button("Save Search(s)"),
        "create_search_btn"=>button("Create Search"),
        "remove_search_btn"=>button("Remove Search(s)"),
        "active" => dropdown(searches["active"], label="Active Searches", multiple=true),
        "inactive" => dropdown(searches["inactive"], label="Inactive Searches", multiple=true))
    )

tracker["page"] = () -> node(:div,
    vbox(
        hbox(hskip(2em),
            tracker["inputs"]["inactive"], hskip(1em),
            vbox(vskip(3em),
                tracker["inputs"]["push_right_btn"],
                tracker["inputs"]["push_left_btn"]), hskip(1em),
            tracker["inputs"]["active"]),
        hbox(hskip(1em),
            tracker["inputs"]["track_search_btn"], hskip(1em),
            tracker["inputs"]["load_search_btn"]),
        hbox(hskip(1em),
            tracker["inputs"]["save_search_btn"], hskip(1em),
            tracker["inputs"]["show_info_btn"], hskip(1em),
            tracker["inputs"]["remove_search_btn"], hskip(1em),
            tracker["inputs"]["create_search_btn"])),
    "Next search running in: "
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
                    add_search(w, inputs)
                    continue
                catch err  # invalid file error
                    println(err)
                    @js w alert("Invalid Search file specified. Is this a .bjs file?")
                    continue
                end
            end
        elseif inputs["create_search_btn"][] > 0
            inputs["create_search_btn"][] = 0
            @async app(search)
            continue

        elseif inputs["remove_search_btn"][] > 0
            inputs["remove_search_btn"][] = 0
            remove_search(w, inputs)
            continue

        elseif inputs["show_info_btn"][] > 0
            inputs["show_info_btn"][] = 0
            show_search_info(w, inputs)
            continue

        elseif inputs["push_right_btn"][] > 0
            inputs["inputs"]["push_right_btn"][] = 0
            push_right(w, inputs)
            continue

        elseif inputs["push_left_btn"][] > 0
            inputs["inputs"]["push_left_btn"][] = 0
            push_left(w, inputs)
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
