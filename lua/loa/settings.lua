-- Top-level requires
local storage   = require('openmw.storage')
local I         = require('openmw.interfaces')
local async     = require('openmw.async')
local calender  = require('openmw_aux.calendar')
local types     = require('openmw.types')
local self      = require('openmw.self')
-- Storage sections
local watcher = storage.playerSection('watcher_for_loa')
local loa = storage.playerSection('library_of_apocrypha')


-- Settings page/group
I.Settings.registerPage { 
    key='WatcherModPage',
    l10n='watcher',
    name='Watcher Mod',
    description='Settings for Library of Apocrypha'
}

print('SEETINGS VIEW TO BE SET')
I.Settings.registerGroup {
  key='SettingsWatcherManageData',
  page='WatcherModPage',
  l10n='watcher',
  name='Manage Data',
  description='Select, print or delete data',
  permanentStorage=false,
  settings = {
    {
      key='selectData',
      renderer='select',
      name='Select Data',
      description='Pick a save slot',
      default='EMPTY',
      argument={ items={'EMPTY'}, l10n='watcher' }
    },
    {
      key='isPrint', renderer='checkbox',
      name='Print Data?', default=false,
      description='Log data for upload'
    },
    {
      key='isDelete', renderer='checkbox',
      name='Delete Data?', default=false,
      description='Delete selected slot'
    },
  }
}

I.Settings.registerGroup {
    l10n = 'watcher',
    key = 'SettingsWatcherViewData',
    page = 'WatcherModPage',
    name = 'View Data',
    description = 'Time',
    permanentStorage = false,
    settings = {
        {
            key = 'gameTime',
            name = 'In-Game Creation Time:',
            renderer = 'showSaveDate',
            argument = {
                textSize = 12
            }
        },
        {
            key = 'osTime',
            name = 'Real Time Creation Time:',
            renderer = 'showSaveDate',
            argument = {
                textSize = 12
            }
        },
        {
            key = 'saveFileName',
            name = 'Save File Name',
            renderer = 'showSaveDate',
            argument = {
                textSize = 12
            }
        }
    }
}




local function getBookEntriesKeys(characterData)
    --local dictionary = section:get('tracked_books')
    print('dictionary is what:', characterData)
    if characterData == nil then
        print('dictionary is nil:', characterData)
        return {'EMPTY'}
    end
    --dictionary is not nil
    print('dictionary is NOT nil:',characterData)
    local keys = {}
    for saveSlotIndex, _ in pairs(characterData) do
        table.insert(keys, saveSlotIndex)
    end
    return keys
end

local function updateSelect(characterData)
    -- print('should not be here on first call')
    local saveSlotIndexes = getBookEntriesKeys(characterData)
    print('from getBookEntriesKeys items is:', saveSlotIndexes)
    print('first item, item[1]:',saveSlotIndexes[1])
    I.Settings.updateRendererArgument('SettingsWatcherManageData', 'selectData', {
        l10n = 'watcher',
        items = saveSlotIndexes,
        default = saveSlotIndexes[1]
    })
    local watcherManageData = storage.playerSection('SettingsWatcherManageData')
    watcherManageData:setLifeTime(storage.LIFE_TIME.Temporary)
    watcherManageData:set('selectData', saveSlotIndexes[1]) -- removing this prevents infinite recursion implenting delete labels need updating
end

local function updateTextFields(selectedSlot)
    local saveSlot = loa:get(watcher:get('directory'))[selectedSlot]
    print('updateTextFields:', saveSlot['game_time'])

    I.Settings.updateRendererArgument('SettingsWatcherViewData', 'gameTime', {
        text = calender.formatGameTime('%x', saveSlot['game_time'])
    })
    I.Settings.updateRendererArgument('SettingsWatcherViewData', 'osTime', {
        text = os.date('%x', saveSlot['creation_time'])
    })
    I.Settings.updateRendererArgument('SettingsWatcherViewData', 'saveFileName', {
        text = saveSlot['save_file_name']
    })
end


loa:subscribe(async:callback(function (section, key)
    print('loa:subscribe:section=',section)
    print('loa:subscribe:key=',key)
    updateSelect(loa:get(key))
end))

-- Update dropdown options when storage changes
watcher:subscribe(async:callback(function(sec, key)
    if key == 'directory' then --directory has been changed
        local directory = watcher:get('directory')
        if directory then --confirms directory exists
            local characterData = loa:get(directory)
            updateSelect(characterData)
        end
    end
end))


-- Handle actions when checkboxes change
storage.playerSection('SettingsWatcherManageData'):subscribe(async:callback(function(section, key)
    local section = storage.playerSection('SettingsWatcherManageData')
    local value = section:get(key)
    local selectedSaveSlot = section:get('selectData')
    print('SettingsWatcherManageData:value=',value)
    if selectedSaveSlot == 'EMPTY' then
        return
    end
    if key == 'isPrint' and value == true then
        print('it will be printed')
        types.Player.sendMenuEvent(self,'PrintBooksTracked', selectedSaveSlot)
    elseif key == 'isDelete' and value == true then
        -- delete logic
        print('is is to be deleted')
        local directory = watcher:get('directory')
        local characterData = loa:getCopy(directory)
        table.remove(characterData, selectedSaveSlot)
        loa:set(watcher:get('directory'), characterData)
        updateSelect(characterData)

    elseif key == 'selectData' then
        updateTextFields(selectedSaveSlot)
  end
end))
