fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Kakarot'
description 'Taxi Job'
version '1.2.0'

dependency 'qb-core'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/*.lua',
    'config.lua',
}

client_scripts {
    'client/*.lua'
}

server_script 'server/main.lua'