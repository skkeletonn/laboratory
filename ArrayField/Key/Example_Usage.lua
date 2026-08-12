local KeySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/skkeletonn/laboratory/refs/heads/main/ArrayField/Key/KeySystemV3.lua"))()
KeySystem:CreateKeyUI({
    Title = "Vadrifts Key System",
    Subtitle = "This script is protected with a key system.",
    Note = "get key from discord gng >:(",
    Keys = {"Hello123", "Bye321"}, -- You can put however many keys here and these will be the keys unless if you enable validatefromserver or discordvalidation
    SaveKey = false, -- decides if the key system will appear on any execution of the script or once every savekeyduration if you've put sumn
    SaveKeyDuration = 25, -- how long before the savekey stops working. You can just remove this line if you want it saved forever or until the key changes.
    FileName = "My_SriptHub1",
    Trial = { ----------------------------------------------   you can remove these things like Trial, DiscordValidation, ValidateKeyFromServer n VIP if youre just not using them at all.  ---------------------------------------------- 
        Enabled = false, --enabling this makes 
        Duration = "15m", -- you can put m for minutes, h for hours n d for days ,, also like 3d15h or just 25h. if u js enter a number n no suffix its finna do hours
    },
    DiscordValidation = { -- join our discord https://vadrifts.onrender.com/discord to be able to invite the 25ms bot to your server (then do /ks setup)
        Enabled = false, -- in your discord you can force people to be in your server for the keys to work (it wont work if they leave) + you can make it so that they also need to do an adlink to get the key
        ValidateURL = 'https://vadrifts.onrender.com/api/validate-guild-key', -- you can use our service <3
        APISecret = 'you will be able to replace the whole discoerd validation when the bot gives u the correct snippet'
    },
    ValidateKeyFromServer = {
        Enabled = false, --enabling this would make it so that the users have to go through your website then through an adlink and back to get a key (hard to do if you want the key to be protected or not the same for everyone)
        ValidateURL = "https://your-server.com/validate", -- much more dificult to make, you have to brainstorm a website yourself.
    },
    VIP = {
        Enabled = false, -- enabling this would allow certain hwids to instantly skip the key system
        PastebinURL = "", -- in the pastebin raw link that you'd make it has to have ["HWID 1", "HWID 2"] (get hwids from https://raw.githubusercontent.com/skkeletonn/random/refs/heads/main/roblox/copy_r_hwid.lua)
        LocalList = {} -- you can put the ["HWID 1", "HWID 2"] here but this is not as secure. ANTT HTTP PROTECTS YOUR PASTEBIN LINK <33
    },
    Action = {
        Link = "https://discord.gg/WDbJ5wE2cR", --put discord link or somewhere else where a user would get the key. e.g website or generic unportected adlink like work.ink or lootlabs
    },
    Callback = function()
    print("omg you completed the key system!") -- replace this with your loadstring or your script whatever you want.
    --more content if u want
    end-- dont forget about this part at the very end of your script,, this is a part of the key system n what it'd launch when you complete it
})-- this too dont forget this too
