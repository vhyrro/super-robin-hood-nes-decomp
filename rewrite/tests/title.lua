local frames = 0
local saw_title = false

emu.addMemoryCallback(function()
    saw_title = true
end, emu.callbackType.exec, @@titlescreen@@, @@titlescreen@@)

emu.addEventCallback(function()
    frames = frames + 1
    if saw_title then
        emu.stop(0)
    elseif frames > 1200 then
        emu.stop(1)
    end
end, emu.eventType.endFrame)
