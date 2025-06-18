local core              = require('openmw.core')
local types             = require('openmw.types')
local storage           = require('openmw.storage')
local self              = require('openmw.self')
local watcher    = storage.playerSection('watcher_for_loa')

local function onInitOrOnLoad()
    print('onInitOrOnLoad init.lua')
    types.Player.sendMenuEvent(self, 'GetCurrentDirectory')
    print('onInitOrOnLoad:GetCurrentDirectory:',watcher:get('directory'))
end

local function onSave()
    local gameTime = tostring(core.getGameTime()) --always first line for accuracy
    print(watcher:get('onSave:tracked_books'))
    print(watcher:get('onSave:directory'))
    if watcher:get('tracked_books') and watcher:get('directory') then
        types.Player.sendMenuEvent(self, 'GameSaved', gameTime)
    else
        print('****NOTHING SAVED****') --REMOVE THIS FOR PRODUCTION
    end
    
end

local function UiModeChanged(data)
    local time = core.getGameTime()
    if (data.newMode == 'Book' or data.newMode == 'Scroll') and types.Book.objectIsInstance(data.arg) then
        print(data.arg.id)
        local id = types.Book.record(data.arg).id
        local booksTracked = watcher:getCopy('tracked_books') or {}
        if not booksTracked[id] then
            print(id, ' is new:UiModeChanged')
            booksTracked[id] = {
                ['discoverd_on'] = time,
                ['entries'] = {}
            }
        end
        booksTracked[id]['entries'][data.arg.id] = {
            ['last_interacted'] = time,
            ['cell_name'] = nil,
            ['cell_region'] = nil,
            ['cell_isExterior'] = nil
        }
        if data.arg.cell then
            booksTracked[id]['entries'][data.arg.id]['cell_name'] = data.arg.cell.name or nil
            booksTracked[id]['entries'][data.arg.id]['cell_region'] = data.arg.cell.region or nil
            booksTracked[id]['entries'][data.arg.id]['cell_isExterior'] = data.arg.cell.isExterior or nil
        end
        watcher:set('tracked_books', booksTracked)
    end
end

return {
    engineHandlers = {
        onInit = onInitOrOnLoad,
        onLoad = onInitOrOnLoad,
        onSave = onSave,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged
    }
}