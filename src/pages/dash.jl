dash = Dict(
    "title" => "DASHBOARD ~ bejolder",
    "size" => (950, 700),
    "page" => node(:div,
        search["page"],
        tracker["page"]),
    "events" => () -> @async while true
            println(" Dash events started! breaking loop now...")
            break
        end
    )
