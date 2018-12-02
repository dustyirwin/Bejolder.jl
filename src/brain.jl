
struct Item
    market::String
    id::String
    name::Union{String, Nothing}
    url::Union{String, Nothing}
    sales_price::Union{Dict{DateTime, Float64}, Nothing}
    shipping::Union{String, Nothing}
    imgs::Union{Vector{String}, Nothing}
    sold_date::Union{String, Nothing}
    description::Union{String, Nothing}
    query_url::Union{String, Nothing}
end

function get_stats(items, stats=Dict())
    stats["prices"] = [collect(item.sales_price)[end][2] for item in items if item.sales_price != nothing && collect(item.sales_price)[end][2] > 0 ]
    stats["render"] = "valid item count: $(length(stats["prices"])) mean: \$$(round(mean(stats["prices"]))) std dev: \$$(round(std(stats["prices"])))"
    return stats
end

function export_CSV(filename::String, results)
    # header=[:market, :id, :name, :url, :sales_price, :sold_date, :query_url] # :shipping, :imgs, :description

    for items in results
        t = table(
            [item.market for item in items],
            [item.id for item in items],
            [try replace(item.name, ","=>"") catch end for item in items],
            [try collect(item.sales_price)[end][2] catch end for item in items],
            [item.sold_date for item in items],
            [item.url for item in items],
            [item.query_url for item in items],
            )

        open(filename, "a") do file
            for i in 1:length(t)
                write(file, string(t[i]))
                write(file, "\n")
            end
        end
    end
    return
end
