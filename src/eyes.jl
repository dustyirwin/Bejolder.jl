headers = Dict(
    1=>Dict("User-agent"=>"Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36"),
    2=>Dict("User-agent"=>"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.149 Safari/537.36"),
    3=>Dict("User-agent"=>"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36"),)

proxies = Dict(
    1=>"https://162.210.211.225:57364",
    2=>"https://45.79.64.225:3128",)  # from https://free-proxy-list.net/

function stare(market::Dict, item::Item, headers=headers)
    response = HTTP.get(item["url"], headers=headers)
    page_html = parsehtml(String(response.body))
    item_details = market["item_details"](page_html)
    item = merge(item, item_details)
    # todo: saveItem to db
    return item
end # ::Item

function scan(market::Dict, keywords::String, category="", filters=[], max_pages=1, headers=headers)
    items = []
    headers = headers[rand(1:length(headers))]

    @sync for page in 1:max_pages
        query = market["query"](keywords)
        query_url = market["query_url"](query, category, filters, page)
        println("$(uppercase(market["name"])) query url: $query_url")

        @time @async begin
            if page == 1
                response = HTTP.get(query_url, headers)
                item_datas = market["item_datas"](response)
                items = market["items"](item_datas, query_url)
            else
                sleep(page*rand(2:0.1:3)) # throttle
                response = HTTP.get(query_url, headers)
                item_datas = market["item_datas"](response)
                append!(items, market["items"](item_datas, query_url))
            end # if
        end # begin
    end # for

    return items
end # ::Vector{Item}

function get_prices(items::Vector{Item}, stats=Dict())
    stats["prices"] = [
        collect(item.sales_price)[end][2] for item in items
            if typeof(item.sales_price) != Missing && collect(item.sales_price)[end][2] > 0 ]
    stats["render"] = "valid item count: $(length(stats["prices"])) mean: \$$(round(mean(stats["prices"]))) std dev: \$$(round(std(stats["prices"])))"
    return stats
end # ::Dict
