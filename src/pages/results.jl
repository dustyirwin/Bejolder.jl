function render(item::Item)
    node(:div,
        node(:a, item.name, attributes=Dict("href"=>item.url, "target"=>"_blank")),
        node(:div, "\$$(collect(item.sales_price)[end][2])"),
        node(:a, node(:img, src=item.imgs[1]), attributes=Dict("href"=>item.url, "target"=>"_blank")),
            attributes=Dict())
end

function render(items::Vector{Item})
    dom"div.column"(
        node(:p, "$(uppercase(items[1].market)) - $(get_prices(items)["render"]))",
        node(:ol, items...), ))
end

function render(query::Query)
    node(:div, plot(query.plot_obs, layout=1, ylab="\$", xlab="#obs",
        title="$(uppercase(query.market)): $(query.keywords)"))
end

function render(queries::Vector{Query})
    dom"div.columns"(queries...)
end

function render(_results::Vector{Any})
    dom"div.columns"(_results...)
end

results = Dict(
    "size" => (1000, 800),
    "title" => "SEARCH RESULTS ~ bejolder",
    "inputs" => (keywords::String) -> Dict(
        "export_CSV" => button("Export Data to CSV"),
        "filename_CSV" => textbox(value="$(replace(keywords, " "=>"_"))_$(string(now())[1:10]).csv"),
        "save_search_btn" => button("Save Search"),
        "filename_BJS" => textbox(value="$(replace(keywords, " "=>"_"))_$(string(now())[1:10]).bjs")),
    "page" => (inputs::Dict, _results::Vector{Any}, _search::Search) ->
        node(:div,
            hbox(
                hskip(1em), inputs["filename_CSV"], hskip(0.5em), inputs["export_CSV"],
                hskip(1em), inputs["filename_BJS"], hskip(0.5em), inputs["save_search_btn"],),
            render(_search.queries),
            render(_results)),
    "events" => (r::Window, inputs::Dict, _results::Vector{Any}, _search::Search) ->
        @async while true
            if inputs["export_CSV"][] > 0
                inputs["export_CSV"][] = 0
                export_CSV("./tmp/" * inputs["filename_CSV"][], _results)
                @js r alert("Results saved to .csv file!")
                continue
            elseif inputs["save_search_btn"][] > 0
                inputs["save_search_btn"][] = 0
                JLD2.@save "./tmp/" * inputs["filename_BJS"][] _search
                @js r alert("Search saved to file.")
                continue
            else
                sleep(0.1)
            end
        end) # Dict
