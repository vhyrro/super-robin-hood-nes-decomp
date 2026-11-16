local frames = 0
local saw_title = false

emu.addMemoryCallback(function()
    emu.write(0x07FF, 151, emu.memType.nesDebug)
end, emu.callbackType.exec, @@start@@, @@start@@)

emu.addMemoryCallback(function()
    saw_title = true
end, emu.callbackType.exec, @@titlescreen@@, @@titlescreen@@)

emu.addEventCallback(function()
    frames = frames + 1
    if saw_title then
        emu.stop(0)
    elseif frames > 600 then
        emu.stop(1)
    end
end, emu.eventType.endFrame)

emu.addEventCallback(function()
    emu.setInput({ start = frames > 70 }, 0)
end, emu.eventType.inputPolled)
