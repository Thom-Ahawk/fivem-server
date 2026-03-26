fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Jules (FiveM Expert)'
description 'ESX taxi job with NPC missions and fleet tablet garage'
version '1.1.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html'
}
