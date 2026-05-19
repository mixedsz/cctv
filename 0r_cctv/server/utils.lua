function RegisterServerCallback(name, handler)
    if Config.Framework == "qb" then
        Framework.Functions.CreateCallback(name, handler)
    else
        Framework.RegisterServerCallback(name, handler)
    end
end
