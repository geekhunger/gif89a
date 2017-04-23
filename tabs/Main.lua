-- gif89a encoder / decoder

function setup()
    --gif = readGifImage(lfs.DROPBOX.."/gif89a.gif")
    
    local function bin_to_hex(bin)
        local map = {
            ["0000"] = "0",
            ["0001"] = "1",
            ["0010"] = "2",
            ["0011"] = "3",
            ["0100"] = "4",
            ["0101"] = "5",
            ["0110"] = "6",
            ["0111"] = "7",
            ["1000"] = "8",
            ["1001"] = "9",
            ["1010"] = "a",
            ["1011"] = "b",
            ["1100"] = "c",
            ["1101"] = "d",
            ["1110"] = "e",
            ["1111"] = "f"
        }
        return bin:format("%04i"):gsub("[0-1][0-1][0-1][0-1]", map)
    end
    
    local b = "1010"
    print(4-#b%4)
    print(string.format("%04i", b))
end

function draw()
    background(127)
    fill(0)
end
