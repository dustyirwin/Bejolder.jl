
edits = Dict(
    "title" => "EDIT ~ bejolder",
    "size" => (500, 500),
    "page" => (object) -> render(object)
)


render(_search::Search)
    node(:div,
        "keywords: " * _search.name,
        render(_search.queries...))
end

function render(_query::Query)

end







function show_search_info()
    @async for filename in merge(searches["active"][], searches["inactive"][])
        s = Window()
        JLD2.@load filename _search
        body!(s, render(_search))
    end
end
