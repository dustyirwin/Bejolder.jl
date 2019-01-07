markets = Dict()

markets["chewy"] = Dict(
    "id" => 1.0,
    "name" => "chewy",
    "query" => (keywords) -> replace(keywords, " "=>"+"),
    "categories" => OrderedDict("All"=>"", "Cat"=>325, "Dog"=>288, "Small Pet"=>977),
    "filters" => OrderedDict(
        "Dry Food" => "%2FoodForm:Dry+Food",
        "Adult" => "%2CLifestage%3AAdult",
        "Small Breeds" => "%2CBreedSize%3ASmall+Breeds",),
    "query_url" => (query, category, filters=[], page=1) ->
        """https://www.chewy.com/s/?query=$query&page=$page&rh=c:$category$(join(filters))""",
    "item_datas" => (response) -> eachmatch(sel".product-holder", parsehtml(String(response.body)).root),
    "items" => (item_datas, query_url) -> [Item(
        "chewy",  # market
        eachmatch(sel".ga-eec__id", item_html)[1][1].text,  # id
        eachmatch(sel".ga-eec__name", item_html)[1][1].text,  # name
        "https://chewy.com$(eachmatch(sel".product", item_html)[1].attributes["href"])",  # url
        OrderedDict(now()=>parse(Float64, eachmatch(sel"div.ga-eec__price", item_html)[1][1].text[1:end])),  # sales_price
        eachmatch(sel".shipping", item_html)[1][1].text,  # shipping
        ["http:"*img[1].attributes["src"] for img in eachmatch(sel"div.image-holder", item_html)],  # imgs
        nothing,  # sold_date
        "Description goes here...",
        query_url) for item_html in item_datas],
    "item_details" => (item, item_html) -> item.description = eachmatch(
        sel"section.descriptions__content", item_html.root)[1][1][1][1].text)

markets["ebay"] = Dict(
    "id" => 2.0,
    "name" => "ebay",
    "query" => (keywords) -> replace(keywords, " "=>"+"),
    "categories" => OrderedDict(
        "All"=>"",
        "Video Games" => "139973",
        "Video Games & Consoles" => "1249",
        "Pet Supplies" => "1281", ),
    "filters" => OrderedDict(
        "Sold Items" => "&LH_Sold=1&LH_Complete=1",
        "US Only" => "&LH_PrefLoc=1",
        "BIN" => "&LH_BIN=1",
        "Free Shipping" => "&LH_FS=1",
        "Used - Very Good" => "&LH_ItemCondition=4000",
        "Used - Good" => "&LH_ItemCondition=5000",),
    "query_url" => (query, category="", filters=[], page=1, ipg=200) ->
        """https://www.ebay.com/sch/i.html?_from=R40&_nkw=$query$(join(filters))&_dmd=2&_sacat=$category&_pgn=$page&_ipg=$ipg""",
    "item_datas" => (response) -> eachmatch(sel".s-item", parsehtml(String(response.body)).root),
    "items" => (item_datas, query_url) -> [Item(
            "ebay",  # market
            match(r"/\d+/?", eachmatch(sel"a.s-item__link", item_html)[1].attributes["href"]).match[2:end],  # id
            try eachmatch(sel"h3.s-item__title", item_html)[1][2].text catch
                try eachmatch(sel"h3.s-item__title", item_html)[2][2].text catch end end,  # name
            try eachmatch(sel"a", item_html)[1].attributes["href"] catch end,  # url
            try OrderedDict(now()=>parse(Float64, eachmatch(sel"span.s-item__price", item_html)[1][1].text[2:end])) catch
                try OrderedDict(now()=>parse(Float64, eachmatch(sel"span.POSITIVE", item_html)[1][1].text[2:end])) catch end end, # sales_price
            try eachmatch(sel"span.s-item__shipping", item_html)[1][1][1].text catch end,  # shipping
            [img.attributes["src"] for img in eachmatch(sel"img", item_html)],  # imgs
            try eachmatch(sel"span.s-item__ended-date s-item__endedDate", item_html)[1][1].text catch end,  # sold_date
            "Description goes here...",
            query_url,
            ) for item_html in item_datas],
    "item_details" => (item, item_html) -> item.description = "Detailed Description here")

markets["amazon"] = Dict(
    "id" => 3.0,
    "name" => "amazon",
    "query" => (keywords) -> replace(keywords, " "=>"+"),
    "categories" => OrderedDict(
        "All"=>"aps",
        "Video Games"=>"videogames",
        "Cell Phones"=>"mobile",
        "Electronics"=>"electronics",
        "Pet Supplies"=>"pets"),
    "filters" => OrderedDict(
        "None"=>""),
    "query_url" => (query, category="aps", filters=[], page=1) ->
        """https://www.amazon.com/s/ref=nb_sb_noss_$(rand(1:2))?url=search-alias%3D$category&field-keywords=$query&rh=i%3A$category%2Ck%3A$query&lo=$category&page=$page$(join(filters))""",
    "item_datas" => (response) ->
        [i for i in eachmatch(sel"li.s-result-item", parsehtml(String(response.body)).root) if length(i.attributes) > 2],
    "items" => (item_datas, query_url) -> [Item(
            "amazon",
            try item_html.attributes["data-asin"] catch end,
            try eachmatch(sel"h2", item_html)[1].attributes["data-attribute"] catch
                try eachmatch(sel"h2", item_html)[1][1][1].text catch end end,
            try eachmatch(sel"a", item_html)[3].attributes["href"] catch end,
            try Dict(now() => parse(Float64, eachmatch(sel"span.s-price", item_html)[1][1].text[2:end])) catch
                try Dict(now() => parse(Float64, eachmatch(sel"span.a-offscreen", item_html)[1][1].text[2:end])) catch end end,
            nothing,
            [try i.attributes["src"] catch end for i in eachmatch(sel"img.s-access-image", item_html)],
            nothing,
            "description here",
            query_url,
            ) for item_html in item_datas if length(item_html.attributes) > 2],
    "item_details" => (item, item_html) -> "")

markets["walmart"] = Dict(
    "id" => 4.0,
    "name" => "walmart",
    "query" => (keywords) -> replace(keywords, " "=>"+"),
    "categories" => OrderedDict(
        "All"=>"",
        "Video Games"=>2636,
        "Baby"=>5427,
        "Pets"=>5440),
    "filters" => OrderedDict(
        "Rollback"=>"&facet=special_offers%3ARollback",
        "2-day Shipping"=>"&facet=pickup_and_delivery%3A2-Day+Shipping"),
    "query_url" => (query, category="", filters=[], page=1) ->
        """http://api.walmartlabs.com/v1/search?query=$query&format=json&apiKey=$(api_keys["walmart"])""",
    "item_datas" => (response) -> JSON.parse(String(response.body)),
    "items" => (item_datas, query_url) -> [Item(
        "walmart",
        try string(item["itemId"]) catch end,
        try item["name"] catch end,
        try item["productUrl"] catch end,
        try OrderedDict(now()=>item["salePrice"]) catch end,
        try string(item["standardShipRate"]) catch end,
        [try item["mediumImage"] catch end],
        nothing,
        try item["shortDescription"] catch
            try item["longDescription"] catch end end,
        query_url) for item in item_datas["items"]],
    "item_details" => (item_html) -> OrderedDict(
            "description" => eachmatch(Selector(""), item_html.root)),
    )
