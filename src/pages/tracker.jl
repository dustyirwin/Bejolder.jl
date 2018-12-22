

function add_tracked_search()
end

function rm_tracked_search()
end

function show_search_info(inputs)
    for search in merge(tracked_searches["active"], tracked_searches["inactive"])
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

tracker["events"] = (w) ->
    @async while true
        if inputs["load_search"][] != "" && inputs["load_search_btn"][] > 0
            inputs["load_search_btn"][] = 0
            @load inputs["load_search"][] search
            active_searches[ts.name] = search
        else
            sleep(0.1)
        end
    end
