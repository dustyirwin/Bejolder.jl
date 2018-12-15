struct Item
    market::Union{String,Missing}
    id::Union{String,Nothing}
    name::Union{String,Nothing}
    url::Union{String,Nothing}
    sales_price::Union{Dict{DateTime, Float64},Nothing}
    shipping::Union{String,Nothing}
    imgs::Union{Vector{String},Nothing}
    sold_date::Union{String,Nothing}
    description::Union{String,Nothing}
    query_url::Union{String,Nothing}
end

struct TrackedQuery
    market::String
    keywords::String
    category::String
    filters::String
    max_pages::Int64
    query_url::String
    price_stats::Series
    price_pred::StatLearn
    plot_obs::Series
end

struct TrackedSearch
    name::String
    interval::Hour
    tracked_queries::Vector{TrackedQuery}
    created::DateTime
end

function get_prices(items, stats=Dict())
    stats["prices"] = [
        collect(item.sales_price)[end][2] for item in items if item.sales_price != nothing && collect(item.sales_price)[end][2] > 0 ]
    stats["render"] = "valid item count: $(length(stats["prices"])) mean: \$$(round(mean(stats["prices"]))) std dev: \$$(round(std(stats["prices"])))"
    return stats
end

function export_CSV(filename::String, _results)
    df = DataFrame(
        market = [item.market for item in vcat(_results...)],
        id = [typeof(item.id) != String ? missing : item.id for item in vcat(_results...)],
        name = [typeof(item.name) != String ? missing : replace(item.name, ","=>"") for item in vcat(_results...)],
        sales_price = [typeof(item.sales_price) != Dict{DateTime,Float64} ? missing : collect(item.sales_price)[end][2] for item in vcat(_results...)],
        sold_date = [typeof(item.sold_date) != String ? missing : item.sold_date for item in vcat(_results...)],
        url = [typeof(item.url) != String ? missing : item.url for item in vcat(_results...)],
        query_url = [typeof(item.query_url) != String ? missing : item.query_url for item in vcat(_results...)],)

    CSV.write(filename, df)
end

function validate_inputs(inputs::Dict)
end
