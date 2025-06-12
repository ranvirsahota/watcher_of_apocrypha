local menu              = require('openmw.menu')
local storage           = require('openmw.storage')
local watcherModData    = storage.playerSection('WatcherModData')
watcherModData:setLifeTime(storage.LIFE_TIME.GameSession)

local function GetSaveDirectory()
    watcherModData:set('directory', menu.getCurrentSaveDir())
    print('GetSaveDirectory:',watcherModData:get('directory'))
end

local function GameSaved (gameTime)
    local dir = watcherModData:get('directory')
    local characterStorage = storage.playerSection(dir)
    local currentBooksTracked = {['books'] = watcherModData:getCopy('tracked_books')}
    print('isbookstracked reset:', currentBooksTracked)
    local playerSaves = menu.getSaves(dir)
    local latestSaveKey = nil
    for filename, save in pairs(playerSaves) do
        if latestSaveKey == nil then
            latestSaveKey = filename
        end
        if save.creationTime > playerSaves[latestSaveKey].creationTime then
            latestSaveKey = filename
        end
    end
    print('latestSaveKey:GameSaved:',latestSaveKey)

    currentBooksTracked['game_time'] = gameTime
    currentBooksTracked['creation_time'] = playerSaves[latestSaveKey].creationTime
    currentBooksTracked['saveFileName'] = latestSaveKey

    local booksTracked = characterStorage:getCopy('tracked_books') or {}
    table.insert(booksTracked, 1, currentBooksTracked)
    characterStorage:set('tracked_books',booksTracked)
    watcherModData:set('tracked_books', nil)
    print('BOOKS TRACKED START')
    for bookId, bookData in pairs(currentBooksTracked['books']) do
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

return {
    eventHandlers = {
        GetSaveDirectory = GetSaveDirectory,
        GameSaved = GameSaved
    },
}