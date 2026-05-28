--- STEAMODDED HEADER
--- MOD_NAME: Hand of Six Smod
--- MOD_ID: HandOfSixSmod
--- MOD_AUTHOR: [Aiilikecheese, Ryan]
--- MOD_DESCRIPTION: Allows the player to play six cards in one hand rather than five, and adds all the new possible hands this creates. Credit to Luna for the planet art!
--- PRIORITY: 100
--- BADGE_COLOUR: 708391
--- VERSION: 1.0.0

----------------------------------------------
------------MOD CODE -------------------------

-- Register the custom atlas for planet sprites
SMODS.Atlas({
    key = 'new_planets',
    path = 'planets.png',
    px = 71,
    py = 95
})

-- Helper Functions for Evaluation
local function get_flusher(hand)
    local ret = {}
    local suits = {"Spades", "Hearts", "Clubs", "Diamonds"}
    if #hand < 6 then return ret end
    for j = 1, #suits do
        local t = {}
        local suit = suits[j]
        local flush_count = 0
        for i = 1, #hand do
            if hand[i]:is_suit(suit, nil, true) then 
                flush_count = flush_count + 1
                t[#t+1] = hand[i] 
            end 
        end
        if flush_count >= 6 then
            table.insert(ret, t)
            return ret
        end
    end
    return {}
end

local function get_straighter(hand)
    local ret = {}
    if #hand < 6 then return ret end
    local t = {}
    local IDS = {}
    for i = 1, #hand do
        local id = hand[i]:get_id()
        if id > 1 and id < 15 then
            if IDS[id] then
                IDS[id][#IDS[id]+1] = hand[i]
            else
                IDS[id] = {hand[i]}
            end
        end
    end

    local straight_length = 0
    local straighter = false
    local can_skip = next(find_joker('Shortcut')) 
    local skipped_rank = false
    for j = 1, 14 do
        local index = (j == 1 and 14 or j)
        if IDS[index] then
            straight_length = straight_length + 1
            skipped_rank = false
            for k, v in ipairs(IDS[index]) do
                t[#t+1] = v
            end
        elseif can_skip and not skipped_rank and j ~= 14 then
            skipped_rank = true
        else
            straight_length = 0
            skipped_rank = false
            if not straighter then t = {} end
            if straighter then break end
        end
        if straight_length >= 6 then straighter = true end 
    end
    if not straighter then return ret end
    table.insert(ret, t)
    return ret
end

-- Hand Definitions
SMODS.PokerHand({
    key = 'flush_six',
    chips = 180, mult = 18, l_chips = 75, l_mult = 5,
    example = { {'S_A', true}, {'S_A', true}, {'S_A', true}, {'S_A', true}, {'S_A', true}, {'S_A', true} },
    loc_txt = { name = 'Flush Six', description = { '6 cards with the same rank and suit' } },
    evaluate = function(parts, hand)
        local flush = get_flusher(hand)
        local six = get_X_same(6, hand)
        if next(flush) and next(six) then return { six[1] } end
        return {}
    end
})

SMODS.PokerHand({
    key = 'flusher_house',
    chips = 160, mult = 15, l_chips = 65, l_mult = 4,
    example = { {'C_9', true}, {'C_9', true}, {'C_9', true}, {'C_9', true}, {'C_7', true}, {'C_7', true} },
    loc_txt = { name = 'Flusher House', description = { 'A Four of a Kind and a Pair with', 'all cards sharing the same suit' } },
    evaluate = function(parts, hand)
        local flush = get_flusher(hand)
        local four = get_X_same(4, hand)
        local two = get_X_same(2, hand)
        if next(flush) and next(four) and #two >= 2 then
            local r4 = four[1][1].base.value
            local p2
            for i = 1, #two do if two[i][1].base.value ~= r4 then p2 = two[i]; break end end
            if p2 then
                local ret = {}
                for _, v in ipairs(four[1]) do table.insert(ret, v) end
                for _, v in ipairs(p2) do table.insert(ret, v) end
                return {ret}
            end
        end
        return {}
    end
})

SMODS.PokerHand({
    key = 'two_flush_triple',
    chips = 155, mult = 15, l_chips = 60, l_mult = 4,
    example = { {'D_K', true}, {'D_K', true}, {'D_K', true}, {'D_4', true}, {'D_4', true}, {'D_4', true} },
    loc_txt = { name = 'Two Flush Triple', description = { 'A Two of a Triple with all', 'cards sharing the same suit' } },
    evaluate = function(parts, hand)
        local flush = get_flusher(hand)
        local three = get_X_same(3, hand)
        if next(flush) and #three >= 2 then
            local ret = {}
            for _, v in ipairs(three[1]) do table.insert(ret, v) end
            for _, v in ipairs(three[2]) do table.insert(ret, v) end
            return {ret}
        end
        return {}
    end
})

SMODS.PokerHand({
    key = 'six_of_a_kind',
    chips = 150, mult = 15, l_chips = 60, l_mult = 4,
    example = { {'H_A', true}, {'H_A', true}, {'C_A', true}, {'C_A', true}, {'D_A', true}, {'S_A', true} },
    loc_txt = { name = 'Six of a Kind', description = { '6 cards with the same rank' } },
    evaluate = function(parts, hand)
        local six = get_X_same(6, hand)
        if next(six) then return { six[1] } end
        return {}
    end
})

SMODS.PokerHand({
    key = 'straighter_flush',
    chips = 120, mult = 10, l_chips = 55, l_mult = 3,
    example = { {'H_T', true}, {'H_9', true}, {'H_8', true}, {'H_7', true}, {'H_6', true}, {'H_5', true} },
    loc_txt = { name = 'Straighter Flush', description = { '6 cards in a row (consecutive ranks) with', 'all cards sharing the same suit' } },
    evaluate = function(parts, hand)
        local flush = get_flusher(hand)
        local straight = get_straighter(hand)
        if next(flush) and next(straight) then
            local ret = {}
            for _, v in ipairs(flush[1]) do ret[#ret+1] = v end
            for _, v in ipairs(straight[1]) do
                local in_straight = false
                for _, vv in ipairs(flush[1]) do if vv == v then in_straight = true break end end
                if not in_straight then ret[#ret+1] = v end
            end
            return {ret}
        end
        return {}
    end
})

SMODS.PokerHand({
    key = 'fuller_house',
    chips = 100, mult = 9, l_chips = 50, l_mult = 3,
    example = { {'H_J', true}, {'C_J', true}, {'D_J', true}, {'S_J', true}, {'C_5', true}, {'D_5', true} },
    loc_txt = { name = 'Fuller House', description = { 'A Four of a Kind and a Pair' } },
    evaluate = function(parts, hand)
        local four = get_X_same(4, hand)
        local two = get_X_same(2, hand)
        if next(four) and #two >= 2 then
            local r4 = four[1][1].base.value
            local p2
            for i = 1, #two do if two[i][1].base.value ~= r4 then p2 = two[i]; break end end
            if p2 then
                local ret = {}
                for _, v in ipairs(four[1]) do table.insert(ret, v) end
                for _, v in ipairs(p2) do table.insert(ret, v) end
                return {ret}
            end
        end
        return {}
    end
})

SMODS.PokerHand({
    key = 'two_of_a_triple',
    chips = 50, mult = 6, l_chips = 40, l_mult = 2,
    example = { {'H_A', true}, {'S_A', true}, {'D_A', true}, {'H_T', true}, {'C_T', true}, {'S_T', true} },
    loc_txt = { name = 'Two of a Triple', description = { 'Two Three of a Kinds with different ranks' } },
    evaluate = function(parts, hand)
        local three = get_X_same(3, hand)
        if #three >= 2 then
            local ret = {}
            for _, v in ipairs(three[1]) do table.insert(ret, v) end
            for _, v in ipairs(three[2]) do table.insert(ret, v) end
            return {ret}
        end
        return {}
    end
})

SMODS.PokerHand({
    key = 'flusher',
    chips = 45, mult = 6, l_chips = 25, l_mult = 2,
    example = { {'S_A', true}, {'S_J', true}, {'S_9', true}, {'S_8', true}, {'S_7', true}, {'S_3', true} },
    loc_txt = { name = 'Flusher', description = { '6 cards that share the same suit' } },
    evaluate = function(parts, hand)
        local flush = get_flusher(hand)
        if next(flush) then return { flush[1] } end
        return {}
    end
})

SMODS.PokerHand({
    key = 'straighter',
    chips = 40, mult = 6, l_chips = 35, l_mult = 2,
    example = { {'H_T', true}, {'D_9', true}, {'H_8', true}, {'C_7', true}, {'S_6', true}, {'D_5', true} },
    loc_txt = { name = 'Straighter', description = { '6 cards in a row (consecutive ranks)' } },
    evaluate = function(parts, hand)
        local straight = get_straighter(hand)
        if next(straight) then return { straight[1] } end
        return {}
    end
})

SMODS.PokerHand({
    key = 'three_pair',
    chips = 35, mult = 3, l_chips = 20, l_mult = 2,
    example = { {'S_Q', true}, {'C_Q', true}, {'S_5', true}, {'D_5', true}, {'H_4', true}, {'C_4', true} },
    loc_txt = { name = 'Three Pair', description = { '3 pairs of cards with different ranks' } },
    evaluate = function(parts, hand)
        local two = get_X_same(2, hand)
        if #two >= 3 then
            local ret = {}
            for _, v in ipairs(two[1]) do table.insert(ret, v) end
            for _, v in ipairs(two[2]) do table.insert(ret, v) end
            for _, v in ipairs(two[3]) do table.insert(ret, v) end
            return {ret}
        end
        return {}
    end
})

-- Planets Definitions
local new_planets = {
    {name = 'Haumea', key = 'haumea', hand = 'three_pair', x = 0, y = 0},
    {name = 'Varuna', key = 'varuna', hand = 'two_of_a_triple', x = 1, y = 0},
    {name = 'Orcus', key = 'orcus', hand = 'fuller_house', x = 2, y = 0},
    {name = 'Salacia', key = 'salacia', hand = 'straighter', x = 3, y = 0},
    {name = 'Varda', key = 'varda', hand = 'six_of_a_kind', x = 4, y = 0},
    {name = 'Makemake', key = 'makemake', hand = 'flusher', x = 0, y = 1},
    {name = 'Gonggong', key = 'gonggong', hand = 'two_flush_triple', x = 1, y = 1},
    {name = 'Quaoar', key = 'quaoar', hand = 'flusher_house', x = 2, y = 1},
    {name = 'Sedna', key = 'sedna', hand = 'straighter_flush', x = 3, y = 1},
    {name = 'Ixion', key = 'ixion', hand = 'flush_six', x = 4, y = 1}
}

for _, p in ipairs(new_planets) do
    SMODS.Consumable({
        key = p.key,
        set = 'Planet',
        config = { hand_type = p.hand, softlock = true },
        pos = { x = p.x, y = p.y },
        atlas = 'new_planets',
        loc_txt = {
            name = p.name,
            description = { "Level up", "{C:attention}" .. p.name .. "{}" }
        }
    })
end

-- Override Highlight System & Play Check to Allow 6 Cards
local cardarea_add_to_highlighted = CardArea.add_to_highlighted
function CardArea:add_to_highlighted(card, silent)
    if self == G.hand then
        if #self.highlighted >= 6 then
            card:highlight(false)
        else
            self.highlighted[#self.highlighted+1] = card
            card:highlight(true)
            if not silent then play_sound('cardSlide1', 0.85, 1) end
        end
        if G.STATE == G.STATES.SELECTING_HAND then
            self:parse_highlighted()
        end
    else
        cardarea_add_to_highlighted(self, card, silent)
    end
end

local can_play_ref = G.FUNCS.can_play
G.FUNCS.can_play = function(e)
    if #G.hand.highlighted <= 0 or (G.GAME.blind and G.GAME.blind.block_play) or #G.hand.highlighted > 6 then 
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
        e.config.colour = G.C.BLUE
        e.config.button = 'play_cards_from_highlighted'
    end
end

-- Special Display Texts (Imperial Flush)
local get_poker_hand_info_ref = G.FUNCS.get_poker_hand_info
G.FUNCS.get_poker_hand_info = function(_cards)
    local text, loc_disp_text, poker_hands, scoring_hand, disp_text = get_poker_hand_info_ref(_cards)
    
    if text == 'Straighter Flush' then
        local min = 9
        for j = 1, #scoring_hand do
            if scoring_hand[j]:get_id() < min then min = scoring_hand[j]:get_id() end
        end
        if min >= 9 then 
            disp_text = 'Imperial Flush'
            loc_disp_text = 'Imperial Flush'
        end
    end
    
    return text, loc_disp_text, poker_hands, scoring_hand, disp_text
end

----------------------------------------------
------------MOD CODE END----------------------
