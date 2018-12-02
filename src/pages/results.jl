function render(item::Item)
    if item.name != nothing && item.sales_price != nothing && item.imgs != nothing
        node(:div,
            node(:a, "$(uppercase(item.market)) - $(item.name)", attributes=Dict("href"=>item.url, "target"=>"_blank")),
            node(:div, "\$$(collect(item.sales_price)[end][2])"),
            node(:a, node(:img, src=item.imgs[1]), attributes=Dict("href"=>item.url, "target"=>"_blank")),
                attributes=Dict())
    else
        node(:div)
    end
end

function render(items::Vector{Item})
    dom"div.column"(
        node(:p, get_stats(items)["render"]),
        node(:ol, items...), )
end

function render(results::Array{Any,1})
    dom"div.columns"(results...)
end

results = Dict(
    "size" => (1000, 800),
    "title" => "SEARCH RESULTS ~ bejolder",
    "inputs" => (keywords) -> Dict(
        "export_CSV" => button("Export to CSV"),
        "filename" => textbox(value="$(replace(keywords, " "=>"_"))_$(string(now())[1:10]).csv"),
        "save_DB" => button("Save to DB")),
    "page" => (inputs, results) ->
        node(:div,
            hbox(inputs["save_DB"], hskip(1em), inputs["filename"], inputs["export_CSV"], "  8 columns max displayed"),
            render(results)),
    "events" => (w, inputs, results) ->
        @async while true
            if inputs["export_CSV"][] > 0
                inputs["export_CSV"][] = 0
                export_CSV(inputs["filename"][], results)
                @js w alert("Results saved to file!")

            elseif inputs["save_DB"][] > 0
                inputs["save_DB"][] = 0
                @js w alert("Items added to the DB...j/k!")
                # todo save Items to Postgres? DB
            else
                sleep(0.1)
            end
        end # while
    )
