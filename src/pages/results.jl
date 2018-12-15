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

function render(_results::Array{Any,1})
    dom"div.columns"(_results...)
end

results = Dict(
    "size" => (1000, 800),
    "title" => "SEARCH RESULTS ~ bejolder",
    "inputs" => (keywords::String) -> Dict(
        "export_CSV" => button("Export to CSV"),
        "filename" => textbox(value="$(replace(keywords, " "=>"_"))_$(string(now())[1:10]).csv")),
    "page" => (inputs, _results) ->
        node(:div,
            hbox(hskip(1em), inputs["filename"], inputs["export_CSV"]),
            render(_results)),
    "check_inputs" => (r, results_inputs, _results) ->
        if results["inputs"]["export_CSV"][] > 0
            results["inputs"]["export_CSV"][] = 0
            export_CSV(results_inputs["filename"][], _results)
            @js r alert("Results saved to file!")
            return
        end,
    "events" => (r, results_inputs, _results) ->
        @async while true
            results["check_inputs"](r, results_inputs, _results)
            sleep(0.1)
        end) # Dict
