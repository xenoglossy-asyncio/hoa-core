-- Dump an addon locale table to a tab-separated file. Run with LuaJIT:
--   luajit tools/i18n/dump_addon_locale.lua <locale.lua> <out.tsv>
local out = assert(io.open(arg[2], "w"))
local function escape(text)
    text = text:gsub("\\", "\\\\")
    text = text:gsub("\t", "\\t")
    text = text:gsub("\n", "\\n")
    text = text:gsub("\r", "\\r")
    return text
end

VanillaBonkLocale = {
    tables = {},
    Register = function(_, strings)
        local keys = {}
        for key in pairs(strings) do
            keys[#keys + 1] = key
        end
        table.sort(keys)
        for _, key in ipairs(keys) do
            out:write(escape(key), "\t", escape(strings[key]), "\n")
        end
    end,
}

dofile(arg[1])
out:close()
