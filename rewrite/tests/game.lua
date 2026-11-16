local frames = 0
local saw_title = false
local saw_game = false

emu.addMemoryCallback(function()
    saw_title = true
end, emu.callbackType.exec, @@titlescreen@@, @@titlescreen@@)

emu.addMemoryCallback(function()
    saw_game = true
end, emu.callbackType.exec, @@ingameloop@@, @@ingameloop@@)

emu.addEventCallback(function()
    frames = frames + 1
    if saw_game then
        emu.stop(0)
    elseif frames > 1800 then
        emu.stop(1)
    end
end, emu.eventType.endFrame)

emu.addEventCallback(function()
    emu.setInput({ start = saw_title and frames % 12 < 2 }, 0)
end, emu.eventType.inputPolled)
