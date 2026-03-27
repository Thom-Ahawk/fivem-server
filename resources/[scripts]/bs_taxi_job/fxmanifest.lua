fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'GPT-5.3-Codex'
description 'QBCore taxi job with NPC missions and simplified garage'
version '1.1.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
