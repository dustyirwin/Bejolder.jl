login = Dict(
    "title"=>"LOGIN ~ bejolder",
    "size"=>(500, 600),
    "inputs"=>Dict(
        "username"=>textbox("USERNAME", attributes=Dict("size"=>75)),
        "password"=>textbox("PASSWORD", typ="password"),
        "login_btn"=>button("LOGIN"))
    )

login["page"] = node(:div,
    node(:br),
    node(:img, attributes=Dict(
        "src"=>"https://elmordyn.files.wordpress.com/2012/07/20110223084209-beholder.gif")),
    node(:h2, "beholder"),
    node(:p, "VERSION 0.2"),
    node(:hr),
    node(:p, "No unauthorized access. Please login below."),
    node(:div,
        vbox(
            login["inputs"]["username"],
            login["inputs"]["password"],
            login["inputs"]["login_btn"])),
        attributes=Dict(:align=>"middle")
    )

login["events"] = (w::Window) ->
    @async while true
        if login["inputs"]["login_btn"][] > 0
            login["inputs"]["login_btn"][] = 0

            if login["inputs"]["username"][] in keys(users) && login["inputs"]["password"][] == users[login["inputs"]["username"][]]["password"]
                update_window(w, tracker)
                continue
            else
                @js w alert("Incorrect username or password. Try again.")
                continue
            end
        else
            sleep(0.1)
        end
    end
