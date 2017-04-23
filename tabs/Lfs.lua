----------------------------------------
-- Simple Lua-File-System
-- Get access to raw file data at places where Codea couldn't reach before
----------------------------------------

lfs = {}

lfs.ENV = os.getenv("HOME")
lfs.DOCUMENTS = lfs.ENV.."/Documents"
lfs.DROPBOX = lfs.DOCUMENTS.."/Dropbox.assets"

-- Extend search path of require()
-- default package.path is: /var/containers/Bundle/Application/AC80B6CE-8AEE-422D-8163-4B45033C2171/Codea.app/Frameworks/RuntimeKit.framework/?.lua
package.path = package.path..";"..lfs.DROPBOX.."/?.lua"

local MIME = {
    [".htm"] = "text/html",
    [".html"] = "text/html",
    [".shtml"] = "text/html",
    [".xhtml"] = "text/xhtml+xml",
    [".rss"] = "text/rss+xml",
    [".xml"] = "text/xml",
    [".css"] = "text/html",
    [".txt"] = "text/plain",
    [".text"] = "text/plain",
    [".md"] = "text/markdown",
    [".markdown"] = "text/markdown",
    [".lua"] = "text/x-lua",
    [".luac"] = "application/x-lua-bytecode",
    [".js"] = "application/javascript",
    [".json"] = "application/json",
    [".pdf"] = "application/pdf",
    [".zip"] = "application/zip",
    [".ico"] = "image/x-icon",
    [".jpeg"] = "image/jpeg",
    [".jpg"] = "image/jpeg",
    [".gif"] = "image/gif",
    [".png"] = "image/png",
    [".tif"] = "image/tiff",
    [".tiff"] = "image/tiff",
    [".svg"] = "image/svg+xml",
    [".svgz"] = "image/svg+xml"
}


function lfs.breadcrumbs(path)
    return path:match("(.+)/(.+)(%.[^.]+)$")
end


function lfs.read(file)
    local DIR, FILE, EXT = lfs.breadcrumbs(file)
    local data = io.open(string.format("%s/%s", DIR, FILE..EXT), "r")
    
    if data then
        local content = data:read("*all")
        data:close()
        return content, MIME[EXT]
    end
    
    return false
end


function lfs.write(file, content)
    local DIR, FILE, EXT = lfs.breadcrumbs(file)
    local data = io.open(string.format("%s/%s", DIR, FILE..EXT), "w")
    
    if data then
        wFd:write(td)
        wFd:close()
        return true
    end
    
    return false
end


function lfs.read_binary(file)
    local DIR, FILE, EXT = lfs.breadcrumbs(file)
    local data = io.open(string.format("%s/%s", DIR, FILE..EXT), "rb")
    
    if data then
        local chunks = 512
        local content = ""
        
        while true do
            local bytes = data:read(chunks) -- Read only n bytes per iteration
            if not bytes then break end
            content = content..bytes
        end
        
        data:close()
        
        return content, MIME[EXT]
    end
    
    return false
end


function lfs.write_binary(file, content)
    local DIR, FILE, EXT = lfs.breadcrumbs(file)
    local data = io.open(string.format("%s/%s", DIR, FILE..EXT), "wb")
    
    if data then
        data:write(content) -- You could do it in parts, but oh.
        data:close()
        return true
    end
    
    return false
end
