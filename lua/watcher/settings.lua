-- Top-level requires
local storage   = require("openmw.storage")
local I         = require("openmw.interfaces")
local async     = require("openmw.async")
local calender  = require('openmw_aux.calendar')
-- Storage sections
local watcherSettings = storage.playerSection("WatcherModData")
local characterStorage


local function getBookEntriesKeys(section)
    local dictionary = section:get('tracked_books')
    if dictionary == nil then
        return {'EMPTY'}
    end
    --dictionary is not nil
    local keys = {}
    for saveSlotIndex, _ in pairs(dictionary) do
        table.insert(keys, saveSlotIndex)
    end
    return keys
end

-- Settings page/group
I.Settings.registerPage { 
    key="WatcherModPage",
    l10n="watcher",
    name="Watcher Mod",
    description="Settings for Library of Apocrypha"
}
I.Settings.registerGroup {
  key="SettingsWatcherManageData",
  page="WatcherModPage",
  l10n="watcher",
  name="Manage Data",
  description="Select, print or delete data",
  permanentStorage=false,
  settings = {
    {
      key="selectData",
      renderer="select",
      name="Select Data",
      description="Pick a save slot",
      default="EMPTY",
      argument={ items={"EMPTY"}, l10n="watcher" }
    },
    {
      key="isPrint", renderer="checkbox",
      name="Print Data?", default=false,
      description="Log data for upload"
    },
    {
      key="isDelete", renderer="checkbox",
      name="Delete Data?", default=false,
      description="Delete selected slot"
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
                format = '%x',
                textSize = 12
            }
        },
        {
            key = 'osTime',
            name = 'Real Time Creation Time:',
            renderer = 'showSaveDate',
            argument = {
                format = '%x',
                textSize = 12
            }
        },
        {
            key = 'saveFileName',
            name = 'Save File Name',
            renderer = 'showSaveDate',
            argument = {
                format = '%x',
                textSize = 12
            }
        }
    }
}

local function updateSelect(characterStorage)
    I.Settings.updateRendererArgument("SettingsWatcherManageData", "selectData", {
        l10n = 'watcher',
        items = getBookEntriesKeys(characterStorage)
    })
end

local function updateTextFields(selectedSlot)
    print('updateTextFields:', characterStorage:get('tracked_books')[selectedSlot]['game_time'])
    I.Settings.updateRendererArgument("SettingsWatcherViewData", "gameTime", {
        text = calender.formatGameTime('%x', characterStorage:get('tracked_books')[selectedSlot]['game_time'])
    })
    I.Settings.updateRendererArgument("SettingsWatcherViewData", "osTime", {
        text = os.date('%x', characterStorage:get('tracked_books')[selectedSlot]['creation_time'])
    })
    I.Settings.updateRendererArgument("SettingsWatcherViewData", "saveFileName", {
        text = characterStorage:get('tracked_books')[selectedSlot]['saveFileName']
    })
end


local function subscribeToCharacterStorage(characterStorage)
    characterStorage:subscribe(async:callback(function (section, key)
        updateSelect(characterStorage)
    end))
end

-- Update dropdown options when storage changes
watcherSettings:subscribe(async:callback(function(sec, key)
  if key == "directory" then
    characterStorage = storage.playerSection(watcherSettings:get("directory"))
    updateSelect(characterStorage)

    subscribeToCharacterStorage(characterStorage)
  end
end))


-- Handle actions when checkboxes change
storage.playerSection("SettingsWatcherManageData"):subscribe(async:callback(function(section, key)
    local value = storage.playerSection(section):get(key)
    print('SettingsWatcherManageData:value=',value)
    if key == "isPrint" and value == true then
        print('it will be printed')
    elseif key == "isDelete" and value == true then
        -- delete logic
        print('is is to be deleted')
        --table.remove(booksTracked, selectedkey)
    elseif key == 'selectData' then
        updateTextFields(value)
  end
end))
