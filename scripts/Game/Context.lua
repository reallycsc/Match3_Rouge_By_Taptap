local Context = {
    BOARD_SIZE = 0,
    GEM_TYPES = 0,
    MATCH_DAMAGE_RADIUS = 0,
    SWAP_DURATION = 0,
    CLEAR_DURATION = 0,
    DROP_DURATION = 0,
    MAX_CASCADE_COMBO = 0,
    GEM_COLORS = {},
}

return setmetatable(Context, { __index = _G })
