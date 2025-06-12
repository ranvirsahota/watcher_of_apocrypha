local I         = require("openmw.interfaces")
local ui        = require("openmw.ui")
local calendar  = require("openmw_aux.calendar")
local util      = require('openmw.util')

I.Settings.registerRenderer("showSaveDate", function(_, _, arg)
    return {
        type = ui.TYPE.Text,
        props = {
            text        = arg.text,
            textSize    = 12,
            textColor   = util.color.rgb(1, 1, 1),
            autoSize    = true,
        }
    }
end)