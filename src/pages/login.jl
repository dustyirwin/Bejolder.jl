function validate_user(w, inputs)
    if inputs["login_btn"][] > 0
        inputs["login_btn"][] = 0

        if inputs["username"][] in keys(users) && inputs["password"][] == users[inputs["username"][]]["password"]
            update_window(w, pages["search"])
            return true
        else
            @js w alert("Incorrect username or password. Try again.")
            return false
        end
    end
end

login = Dict(
    "title" => "LOGIN ~ beholdia",
    "size" => (500, 600),
    "username" => textbox("enter username", attributes=Dict("size"=>50)),
    "password"=> textbox("enter password", typ="password"),
    "login_btn" => button("LOGIN"))

login["inputs"] = Widget([
    "username"=>login["username"],
    "password"=>login["password"],
    "login_btn"=>login["login_btn"]])

login["page"] = node(:div,
    node(:br,),
    node(:img, attributes=Dict(
        "src"=>"https://elmordyn.files.wordpress.com/2012/07/20110223084209-beholder.gif")),
    node(:h2, "beholder"),
    node(:p, "VERSION 0.2"),
    node(:hr),
    node(:p, "No unauthorized access. Please login below."),
    node(:div, login["inputs"]),
        attributes=Dict(:align=>"middle"))

login["events"] = (w, inputs) ->
    @async while true
        validate_user(w, inputs) == true ? break : sleep(0.5)
    end
