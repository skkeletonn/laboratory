# ArrayField Key System V3

A Roblox key UI with three validation modes, optional free trial, HWID lock, VIP bypass, and saved keys.

```lua
local KeySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/skkeletonn/laboratory/refs/heads/main/ArrayField/Key/KeySystemV3.lua"))()
```

---

## What it does

| Mode | How the key is checked |
|---|---|
| **Static** | `Keys = {"abc"}` in the script |
| **Server** | `GET your-url?key=...` → body is `true` / `false` |
| **Discord** | `POST` `{key, hwid, secret}` to your API (HWID lock + membership) |

Plus:

- **Trial** — skip the key window for `15m` / `12h` / `4d` / etc. on first run (per device)
- **VIP** — listed HWIDs never see the UI
- **SaveKey** — remember a valid key locally (`SaveKeyDuration` hours, `0` = until you wipe it)
- Animated UI, shake on bad key, mobile tap-to-copy

---

## Quick starts

### Static key

```lua
KeySystem:CreateKeyUI({
    Title = "My Script",
    Note = "Join the Discord for the key.",
    Keys = {"my-secret-key-123"},
    SaveKey = true,
    FileName = "MyScript",
    Callback = function()
        -- load your script here
    end
})
```

### Free trial + static key

First execute on a device skips the UI for 15 minutes. After that, they need a key.

```lua
KeySystem:CreateKeyUI({
    Title = "My Script",
    Note = "Trial is 15 minutes. Then you need a key.",
    Keys = {"my-secret-key-123"},
    Trial = {
        Enabled = true,
        Duration = "15m", -- 15m / 12h / 4d / 35h / 1d12h / "90" (= 90 hours)
    },
    FileName = "MyScript",
    Callback = function()
        -- load your script here
    end
})
```

### Server / work.ink style

Your endpoint: `GET .../validate?key=THE_KEY` → respond with the text `true` or `false`.

```lua
KeySystem:CreateKeyUI({
    Title = "My Script",
    Note = "Click below to get a key.",
    ValidateKeyFromServer = {
        Enabled = true,
        ValidateURL = "https://your-server.com/validate"
    },
    Action = {
        Link = "https://work.ink/your-link" -- copied when they click the button
    },
    SaveKey = true,
    SaveKeyDuration = 24,
    FileName = "MyScript",
    Callback = function() end
})
```

### Discord (Vadrifts /ks)

Add the Vadrifts bot to **your** server (that's where `/ks setup` and `/ks getkey` live):

1. Join **[discord.gg/TtfXNuwMnW](https://discord.gg/TtfXNuwMnW)**
2. Open the bot's profile (**25ms** — ID `1389214056325582898`)
3. **Add App** → pick your server → allow it to create slash commands

Then in *your* server: `/ks setup` (admin) to create the script profile, copy the API secret, paste it below. Users run `/ks getkey`.

Keys are locked to HWID on first use. Leave the server → key dies.

```lua
KeySystem:CreateKeyUI({
    Title = "Vadrifts Key System",
    Subtitle = "This script is protected with a key system.",
    Note = "Run /ks getkey in Discord. Must stay in the server.",
    DiscordValidation = {
        Enabled = true,
        ValidateURL = "https://vadrifts.onrender.com/api/validate-guild-key",
        APISecret = "paste-the-secret-from-/ks-setup"
    },
    Trial = {
        Enabled = true,
        Duration = "15m",
    },
    SaveKey = true,
    SaveKeyDuration = 24,
    FileName = "Vadrifts-STK",
    Action = {
        Link = "https://discord.gg/your-invite",
    },
    Callback = function() end
})
```

`APISecret` is the spoiler from **`/ks setup`** for **that** script. Wrong secret = every key fails.

---

## Config reference

```lua
KeySystem:CreateKeyUI({
    -- required
    Callback = function() end,

    -- UI
    Title = "Key System",
    Subtitle = "Enter Key",
    Note = "What the user should do",

    -- mode 1
    Keys = {"key1", "key2"},

    -- mode 2
    ValidateKeyFromServer = {
        Enabled = true,
        ValidateURL = "https://your-server.com/validate"
    },

    -- mode 3
    DiscordValidation = {
        Enabled = true,
        ValidateURL = "https://vadrifts.onrender.com/api/validate-guild-key",
        APISecret = "from-/ks-setup"
    },

    -- skip the UI on first run for this long (per HWID)
    Trial = {
        Enabled = true,
        Duration = "15m",
    },

    -- remember a good key
    SaveKey = true,
    SaveKeyDuration = 24, -- hours; 0 = no local expiry
    FileName = "UniqueNamePerScript",

    -- "copy link" button
    Action = { Link = "https://..." },

    -- skip UI forever for these HWIDs
    VIP = {
        Enabled = true,
        PastebinURL = "https://pastebin.com/raw/...",
        LocalList = {"hwid1"}
    },

    HWIDSalt = "unique-per-script",
})
```

### Trial

| Field | Meaning |
|---|---|
| `Enabled` | `true` to turn it on |
| `Duration` | `15m`, `12h`, `4d`, `35h`, `1d12h`, or `"90"` (hours) |

- Checked **after VIP**, **before** the key window.
- Clock starts on first execute for that HWID. Reloading mid-trial does not reset it.
- Stored next to the saved key as `FileName_trial.rfld`. Deleting the script does nothing. Deleting that file does (client-side limit).
- When it expires they see the normal key UI on the **next** execute. No mid-session kick.

### DiscordValidation

`POST` JSON:

```json
{ "key": "...", "hwid": "...", "secret": "..." }
```

Expect:

```json
{ "valid": true, "message": "Authenticated" }
```

or `{ "valid": false, "message": "why it failed" }`.

Users: `/ks getkey` · `/ks resetkey` if the device changes. Admins: `/ks setup`.

### Everything else

- **SaveKey** — write the key to `ArrayField/Key System/FileName.rfld`. Discord mode re-checks it with the API every launch (so a leaver still dies).
- **FileName** — unique per script or saved keys/trials collide.
- **HWIDSalt** — unique per script or HWIDs match across your scripts.
- **Action** — optional clipboard button. Omit the table to hide it.
- **VIP** — remote list = JSON array **or** one HWID per line.

---

## Check order

```
1. VIP HWID          → skip everything
2. Trial             → skip UI until Duration is up
3. Saved key         → Discord mode still hits the API
4. User types a key
      DiscordValidation  (if enabled)
      else ValidateKeyFromServer
      else Keys
```

---

## Discord mode (your own backend)

You need a bot, an API, and a DB. **Vadrifts already is that** — join [discord.gg/TtfXNuwMnW](https://discord.gg/TtfXNuwMnW), add **25ms** (`1389214056325582898`) from its profile to your server, then `/ks setup`. Endpoint: `/api/validate-guild-key`.

If you roll your own:

```
user in Discord → /ks getkey → unique key tied to their account
script POSTs key + HWID + secret
API checks: key exists, not expired, still in server, HWID matches (or first use)
leave Discord → key revoked
```

| Situation | Result |
|---|---|
| Key posted anywhere | HWID mismatch |
| Not in the server | Rejected |
| Leaves after getting a key | Auto-revoked |
| Comes back | `/ks getkey` again |
| New device | `/ks resetkey` then `/ks getkey` |

---

## Don't

- Reuse `FileName` or `HWIDSalt` across scripts
- Put the API secret in a public repo / screenshot
- Expect Trial to survive someone deleting `ArrayField/Key System/` — that's client-side
- Mix DiscordValidation **and** ValidateKeyFromServer and expect both to run. Discord wins.
