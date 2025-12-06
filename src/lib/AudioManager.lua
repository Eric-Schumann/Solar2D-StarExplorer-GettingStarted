local AudioManager = {}

local ASSET_PATH = "assets/audio/"

local cache = {
    sounds={},
    streams={}
}

function AudioManager.loadSound(filename)
    if not cache.sounds[filename] then
        local fullPath = ASSET_PATH .. filename
        cache.sounds[filename] = audio.loadSound(fullPath)
    end
    return cache.sounds[filename]
end

function AudioManager.loadStream(filename)
    if not cache.streams[filename] then 
        local fullPath = ASSET_PATH .. filename
        cache.streams[filename] = audio.loadStream(fullPath)
    end
    return cache.streams[filename]
end

function AudioManager.disposeSounds()
    for filename, handle in pairs(cache.sounds) do
        audio.dispose(handle)
        cache.sounds[filename] = nil
    end
end

function AudioManager.disposeStreams()
    for filename, handle in pairs(cache.streams) do 
        audio.dispose(handle)
        cache.streams[filename] = nil
    end
end

function AudioManager.disposeStream(filename)
    audio.dispose(cache.streams[filename])
    cache.streams[filename] = nil
end

function AudioManager.disposeSound(filename)
    audio.dispose(cache.sounds[filename])
    cache.sounds[filename] = nil
end

return AudioManager