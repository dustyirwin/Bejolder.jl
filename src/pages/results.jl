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
        "export_CSV" => button("Export to CSV"),
        "filename" => textbox(value="$(replace(keywords, " "=>"_"))_$(string(now())[1:10]).csv")),
    "page" => (inputs, _results, _search) ->
        node(:div,
            hbox(hskip(1em), inputs["filename"], inputs["export_CSV"]),
            render(_search.queries),
            render(_results)),
    "events" => (r, results_inputs, _results) ->
        @async while true
            if results_inputs["export_CSV"][] > 0
                results_inputs["export_CSV"][] = 0
                export_CSV("./tmp/" * results_inputs["filename"][], _results)
                @js r alert("Results saved to .csv file!")
                continue
            else
                sleep(0.1)
            end
        end) # Dict
