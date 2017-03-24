----------------------------------------
-- GIF89a encoder / decoder
----------------------------------------

-- Convert string or number to its hexadecimal representation
function string.tohex(val, len)
    if type(val) == "number" then return string.format("%0"..(len or 2).."x", val) end
    return val:gsub(".", function(c) return string.format("%0"..(len or 2).."x", string.byte(c)) end)
end


-- Convert hex to little endian notation
function string.tole(hex)
    return hex:gsub("(%x%x)(%x?%x?)", function(n, m) return m..n end)
end


-- Convert hex to integer
function string.toint(hex)
    return math.tointeger(hex:gsub("%x%x", function(cc) return tonumber(cc, 16) end))
end


-- Convert hex to binary
function string.tobin(hex)
    local map = {
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
    }
    return hex:gsub("[0-9a-f]", map)
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
