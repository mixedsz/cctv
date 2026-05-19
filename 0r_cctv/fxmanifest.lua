shared_scripts { '@FiniAC/fini_events.lua' }

fx_version 'cerulean'
game 'gta5'
author 'atiysu'
lua54 'yes'

shared_scripts {
    'settings/config.lua',
    'settings/cameras.lua',
}

client_scripts {
    'client/utils.lua',
    'client/main.lua',
}

server_scripts {
    'settings/serverconfig.lua',
    'server/utils.lua',
    'server/main.lua',
}

ui_page 'ui/index.html'

files {
    'ui/*.*',
    'ui/**/*.*',
}

exports {
    'getMugshotUrl'
}

escrow_ignore{
    'settings/serverconfig.lua',
    'settings/config.lua',
    'settings/cameras.lua',
    'client/utils.lua',
    'client/main.lua',
    'server/utils.lua',
    'server/main.lua',
}
dependency '/assetpacks'