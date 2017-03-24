-- gif89a encoder / decoder

function setup()
    local file = lfs.DROPBOX.."/gif89a.gif"
    local raw_data = lfs.read(file)
    local hex_content = raw_data:tohex()
    local file_pointer = 12
    
    print(hex_content)
    
    local function get_bytes(len, format)
        local from = file_pointer + 1
        local to = from + 2 * len - 1
        local chunk = hex_content:sub(from, to)
        file_pointer = to
        
        if format == "hex" then return chunk end -- return bytes as raw hex values
        if format == "bin" then return chunk:tobin() end -- return packed bytes as binary
        if len > 1 then return chunk:tole():toint() end -- return multibyte integers as little endians
        return chunk:toint() -- return singlebyte integers
    end
    
    local function get_colors(len)
        local colors = {}
        
        for pos = 1, len do
            local r = get_bytes(1)
            local g = get_bytes(1)
            local b = get_bytes(1)
            colors[pos] = color(r, g, b)
        end
        
        return colors
    end
    
    -- Header
    local Signature = raw_data:sub(1, 3)
    local Version = raw_data:sub(4, 6)
    
    -- Logical Screen Descriptor
    local LogicalScreenWidth = get_bytes(2)
    local LogicalScreenHeight = get_bytes(2)
    local ScreenDescriptorPack = get_bytes(1, "bin")
    local GlobalColorTableFlag = ScreenDescriptorPack:sub(1, 1):toint()
    local ColorResolution = ScreenDescriptorPack:sub(2, 4):toint() - 1
    local GlobalColorTableSortFlag = ScreenDescriptorPack:sub(5, 5):toint()
    local SizeOfGlobalColorTable = 2^(ScreenDescriptorPack:sub(6, 8):toint() + 1)
    local BackgroundColorIndex = GlobalColorTableFlag and get_bytes(1) or 0
    local PixelAspectRatio = get_bytes(1)
    PixelAspectRatio = PixelAspectRatio > 0 and (PixelAspectRatio + 15) / 64 or 0
    
    -- Global Color Table
    local GlobalColorTable = GlobalColorTableFlag == 1 and get_colors(SizeOfGlobalColorTable) or nil
    
    -- Main Loop
    local ExtensionIntroducer
    repeat
        ExtensionIntroducer = get_bytes(1, "hex")
        if ExtensionIntroducer ~= "3b" then
            if ExtensionIntroducer == "2c" then -- Image Descriptor
                goto ImageDescriptorHandler
            elseif ExtensionIntroducer == "21" then -- Extension Block
                local ExtensionLabel = get_bytes(1, "hex")
                if ExtensionLabel == "01" then goto PlainTextExtensionHandler
                elseif ExtensionLabel == "ff" then goto ApplicationExtensionHandler
                elseif ExtensionLabel == "fe" then goto CommentExtensionHandler
                elseif ExtensionLabel == "f9" then goto GraphicControlExtensionHandler end
            end
        
            -- Plain Text Extension
            ::PlainTextExtensionHandler:: goto Continue -- not supported
            
            -- Application Extension
            ::ApplicationExtensionHandler:: goto Continue -- not supported
        
            -- Comment Extension
            ::CommentExtensionHandler:: goto Continue -- not supported
        
            -- Graphic Control Extension
            ::GraphicControlExtensionHandler::
            
            local GraphicControlBlockSize = get_bytes(1)
            local GraphicControlPack = get_bytes(1, "bin")
            local GraphicControlReserved = GraphicControlPack:sub(1, 3)
            local DisposalMethod = GraphicControlPack:sub(4, 6):toint()
            local UserInputFlag = GraphicControlPack:sub(5, 5):toint()
            local TransparentColorFlag = GraphicControlPack:sub(6, 6):toint()
            local DelayTime = get_bytes(2)
            local TransparentColorIndex = get_bytes(1)
            local GraphicControlBlockTerminator = get_bytes(1) -- zero length byte
            
            -- Image Descriptor
            ::ImageDescriptorHandler::
            
            local ImageLeftPosition = get_bytes(2)
            local ImageTopPosition = get_bytes(2)
            local ImageWidth = get_bytes(2)
            local ImageHeight = get_bytes(2)
            local ImageDescriptorPack = get_bytes(1, "bin")
            local LocalColorTableFlag = ImageDescriptorPack:sub(1, 1):toint()
            local InterlaceFlag = ImageDescriptorPack:sub(2, 2):toint()
            local LocalColorTableSortFlag = ImageDescriptorPack:sub(3, 3):toint()
            local ImageDescriptorReserved = ImageDescriptorPack:sub(4, 5):toint()
            local SizeOfLocalColorTable = 2^(ImageDescriptorPack:sub(6, 8):toint() + 1)
            
            -- Local Color Table
            local LocalColorTable = LocalColorTableFlag == 1 and get_colors(SizeOfLocalColorTable) or nil
            
            -- Image Data
            --
            
            ::Continue::
        end
    until ExtensionIntroducer == "3b" -- Trailer
end

function draw()
    background(127)
    fill(0)
end
