----------------------------------------
-- GIF89a encoder / decoder
--
-- NOTE: Plain Text Extension, Application Extension and Comment Extension blocks
-- as well as Interlacing are not supported.
----------------------------------------

-- Convert string or number to its hexadecimal representation
function string.tohex(val, len)
    if type(val) == "number" then return string.format("%0"..(len or 2).."x", val) end
    return val:gsub(".", function(c) return string.format("%0"..(len or 2).."x", string.byte(c)) end)
end


-- Return hex as little endian notation
function string.tole(hex)
    return hex:gsub("(%x%x)(%x?%x?)", function(n, m) return m..n end)
end


-- Convert hex to integer
function string.toint(hex)
    return math.tointeger(hex:gsub("%x%x", function(cc) return tonumber(cc, 16) end))
end


-- Convert hex to binary
function string.tobin(hex)
    return hex:gsub("[0-9a-f]", {
        ["0"] = "0000",
        ["1"] = "0001",
        ["2"] = "0010",
        ["3"] = "0011",
        ["4"] = "0100",
        ["5"] = "0101",
        ["6"] = "0110",
        ["7"] = "0111",
        ["8"] = "1000",
        ["9"] = "1001",
        ["a"] = "1010",
        ["b"] = "1011",
        ["c"] = "1100",
        ["d"] = "1101",
        ["e"] = "1110",
        ["f"] = "1111"
    })
end


-- Copy values from first table to second
function table.copy(from, to)
    for _, value in pairs(from) do
        if type(value) == "table" then
            table.copy(value, to)
        else
            table.insert(to, value)
        end
    end
end

-- Concat recursevly all values from given tables
function table.merge(...)
    local dump = {}
    while #arg > 0 do
        table.copy(arg[1], dump)
        table.remove(arg, 1)
    end
    return dump
end


function printf(t, indent)
    if not indent then indent = "" end
    local names = {}
    for n, g in pairs(t) do
        table.insert(names, n)
    end
    table.sort(names)
    for i, n in pairs(names) do
        local v = t[n]
        if type(v) == "table" then
            if v == t then -- prevent endless loop on self reference
                print(indent..tostring(n)..": <-")
            else
                print(indent..tostring(n)..":")
                printf(v, indent.."   ")
            end
        elseif type(v) == "function" then
            print(indent..tostring(n).."()")
        else
            print(indent..tostring(n)..": "..tostring(v))
        end
    end
end


function readGifImage(file)
    local file_raw_data = lfs.read_binary(file)
    local file_hex_data = file_raw_data:tohex()
    local file_pointer = 12
    
    local function get_bytes(len, format)
        local from = file_pointer + 1
        local to = from + 2 * len - 1
        local chunk = file_hex_data:sub(from, to)
        file_pointer = to
        if format == "hex" then return chunk end -- return bits as raw hex values
        if format == "bin" then return chunk:tobin() end -- you should return packed bytes always as binary
        if len > 1 then return chunk:tole():toint() end -- return multibyte integers as little endians
        return chunk:toint() -- return singlebyte integers
    end
    
    local function get_colors(len)
        local colors = {}
        for pos = 0, len - 1 do
            local r = get_bytes(1)
            local g = get_bytes(1)
            local b = get_bytes(1)
            colors[pos] = color(r, g, b)
        end
        return colors
    end
    
    local function init_colorcodes(colors, len)
        local codes = {}
        local lenmap = {[2] = 4, [3] = 8, [4] = 16, [5] = 32, [6] = 64, [7] = 128, [8] = 256}
        local pos = lenmap[len]
        for i = 0, pos - 1 do codes[i] = colors[i] end
        codes[pos] = "cc" -- clear code
        codes[pos + 1] = "eoi" -- end of information code
        return codes
    end
    
    local function get_stream_chunk(block_len, color_table, lzw_min_code_size)
        local block_hex_data = get_bytes(block_len, "hex") -- debug
        local block_bin_data = block_hex_data:tobin()
        local first_code_size = lzw_min_code_size + 1
        
        print("lzw:", lzw_min_code_size)
        print("hex:", block_hex_data) -- debug
        print("bin:", block_bin_data)
        
        for c in block_bin_data:gmatch(string.rep("%d", first_code_size)) do
            print(c)
        end
    end
    
    -- Header
    local Signature = file_raw_data:sub(1, 3)
    local Version = file_raw_data:sub(4, 6)
    
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
    while ExtensionIntroducer ~= "3b" do -- Trailer
        local GraphicControlExtension
        ::continue::
        ExtensionIntroducer = get_bytes(1, "hex")
        
        if ExtensionIntroducer == "21" then -- Any Extension Block
            local ExtensionLabel = get_bytes(1, "hex")
            if ExtensionLabel == "f9" then -- Graphic Control Extension
                GraphicControlExtension = {}
                GraphicControlExtension.ExtensionIntroducer = ExtensionIntroducer
                GraphicControlExtension.ExtensionLabel = ExtensionLabel
                GraphicControlExtension.BlockSize = get_bytes(1)
                local GraphicControlPack = get_bytes(1, "bin")
                GraphicControlExtension.ReservedBits = GraphicControlPack:sub(1, 3)
                GraphicControlExtension.DisposalMethod = GraphicControlPack:sub(4, 6):toint()
                GraphicControlExtension.UserInputFlag = GraphicControlPack:sub(5, 5):toint()
                GraphicControlExtension.TransparentColorFlag = GraphicControlPack:sub(6, 6):toint()
                GraphicControlExtension.DelayTime = get_bytes(2)
                GraphicControlExtension.TransparentColorIndex = get_bytes(1)
                GraphicControlExtension.BlockTerminator = get_bytes(1) -- zero length byte
                goto continue
            elseif ExtensionLabel == "01" then -- Plain Text Extension
            elseif ExtensionLabel == "ff" then -- Application Extension
            elseif ExtensionLabel == "fe" then -- Comment Extension
            end
        elseif ExtensionIntroducer == "2c" then -- Image Descriptor
            local ImageDescriptor = {}
            ImageDescriptor.ImageSeparator = ExtensionIntroducer
            ImageDescriptor.ImageLeftPosition = get_bytes(2)
            ImageDescriptor.ImageTopPosition = get_bytes(2)
            ImageDescriptor.ImageWidth = get_bytes(2)
            ImageDescriptor.ImageHeight = get_bytes(2)
            local ImageDescriptorPack = get_bytes(1, "bin")
            ImageDescriptor.LocalColorTableFlag = ImageDescriptorPack:sub(1, 1):toint()
            ImageDescriptor.InterlaceFlag = ImageDescriptorPack:sub(2, 2):toint()
            ImageDescriptor.LocalColorTableSortFlag = ImageDescriptorPack:sub(3, 3):toint()
            ImageDescriptor.ReservedBits = ImageDescriptorPack:sub(4, 5):toint()
            ImageDescriptor.SizeOfLocalColorTable = 2^(ImageDescriptorPack:sub(6, 8):toint() + 1)
            
            -- Local Color Table
            local LocalColorTable = ImageDescriptor.LocalColorTableFlag == 1 and get_colors(ImageDescriptor.SizeOfLocalColorTable) or nil
            
            -- Image Data
            local PixelIndicesStream = {}
            local LzwMinimumCodeSize = get_bytes(1)
            local SizeOfCurrentSubBlock
            
            while SizeOfCurrentSubBlock ~= 0 do -- Data Stream
                SizeOfCurrentSubBlock = get_bytes(1)
                if SizeOfCurrentSubBlock > 0 then -- Sub Block
                    get_stream_chunk(SizeOfCurrentSubBlock, LocalColorTable or GlobalColorTable, LzwMinimumCodeSize)
                    --cache stream to PixelIndicesStream
                end
            end
        end
    end
    
end
