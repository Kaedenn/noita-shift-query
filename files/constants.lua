-- Global constants for the Fungal Shift Query mod

MIN_SHIFTS = -1     -- values < 0 mean "all"
MAX_SHIFTS = 20     -- the game implicitly supports only 20 shifts

ALL_SHIFTS = -1     -- values < 0 mean "all"

CUTOFF_RARE = 0.2   -- shifts with this probability or lower are "rare"

FLAG_ON = "1"
FLAG_OFF = "0"

--[[ Settings ]]
MOD_ID = "shift_query"

SETTING_PREVIOUS = "previous_count"
SETTING_NEXT = "next_count"
SETTING_LOCALIZE = "localize"
SETTING_ENABLE = "enable"
SETTING_EXPAND = "expand_from"
SETTING_APLC = "include_aplc"
SETTING_REAL = "flask_real"

CONF_PREVIOUS = ("%s.%s"):format(MOD_ID, SETTING_PREVIOUS)
CONF_NEXT = ("%s.%s"):format(MOD_ID, SETTING_NEXT)
CONF_LOCALIZE = ("%s.%s"):format(MOD_ID, SETTING_LOCALIZE)
CONF_ENABLE = ("%s.%s"):format(MOD_ID, SETTING_ENABLE)
CONF_EXPAND = ("%s.%s"):format(MOD_ID, SETTING_EXPAND)
CONF_APLC = ("%s.%s"):format(MOD_ID, SETTING_APLC)
CONF_REAL = ("%s.%s"):format(MOD_ID, SETTING_REAL)

--[[ Material formatting rules ]]
FORMAT_INTERNAL = "internal"
FORMAT_LOCALE = "locale"
FORMAT_BOTH = "both"

--[[ Source material expansion rules ]]
EXPAND_ONE = "one"
EXPAND_ALL = "all"

