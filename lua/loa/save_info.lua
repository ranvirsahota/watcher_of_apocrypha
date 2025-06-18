local menu              = require('openmw.menu')
local storage           = require('openmw.storage')
local ui                = require('openmw.ui')
local loa               = storage.playerSection('library_of_apocrypha')
local watcher           = storage.playerSection('watcher_for_loa')
watcher:setLifeTime(storage.LIFE_TIME.GameSession)

local function printBooksTracked(selectedSaveSlot)
    local booksTracked = loa:get(watcher:get('directory'))[selectedSaveSlot]['tracked_books']
    print('BOOKS TRACKED START')
    for bookId, bookData in pairs(booksTracked) do
        print('Book ID:',bookId)
        print('Discoved On:',bookData['discoverd_on'])
        for entryId, data in pairs(bookData['entries']) do
            print('Entry ID:', entryId)
            print('Last Interacted:', data['last_interacted'])
            print('Name:', data['cell_name'])
            print('Region:', data['cell_region'])
            print('Is Exterior:', data['cell_isExterior'])
        end
    end
    print('BOOKS TRACKED END')
end

local function getCurrentDirectory()
    local directory = menu.getCurrentSaveDir()
    if  directory then
        watcher:set('directory', directory)
    else
        ui.showMessage('WARNING: No directory found save as soon as you can.')
        watcher:set('directory', nil)
    end
    print('GetSaveDirectory:',watcher:get('directory'))
end

local function gameSaved (gameTime)
    local dir = watcher:get('directory')
    local playerSaves = menu.getSaves(dir)
    local latestSaveFileName = nil
    local booksTracked = watcher:getCopy('tracked_books')
    watcher:set('tracked_books', nil)
    for filename, save in pairs(playerSaves) do
        if latestSaveFileName == nil then
            latestSaveFileName = filename
        end
        if save.creationTime > playerSaves[latestSaveFileName].creationTime then
            latestSaveFileName = filename
        end
    end
    print('latestSaveKey:GameSaved:',latestSaveFileName)

    local charactersPlaythroughhData = loa:getCopy(dir) or {}

    table.insert(charactersPlaythroughhData, 1, {
        ['game_time'] = gameTime,
        ['creation_time'] = playerSaves[latestSaveFileName].creationTime,
        ['save_file_name'] = latestSaveFileName,
        ['tracked_books'] = booksTracked
    })
    print('BOOKS TRACKED START')
    loa:set(dir, charactersPlaythroughhData)
    printBooksTracked(1)
    local isReset = watcher:get('tracked_books')
    if isReset then
        print('saveINFO:isRest not nil', nil)
    else
        print('saveINFO:isRest is nil')
    end
end


return {
    eventHandlers = {
        GetCurrentDirectory = getCurrentDirectory,
        GameSaved = gameSaved,
        PrintBooksTracked = printBooksTracked
    },
}