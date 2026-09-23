-- Exercise the packaged Lua parser methods without network access.
local source_path = assert(arg[1], "parser source path is required")
local source_file = assert(io.open(source_path, "r"))
local source = source_file:read("*a")
source_file:close()
source = source:gsub("^#![^\n]*\n", "")
local marker = assert(source:find("local Summarize = {", 1, true))
package.preload["ltn12"] = function() return {} end
local Parser = assert(loadstring(source:sub(1, marker - 1) .. "\nreturn BlackListParser\n"))()

local parser = Parser:new()
parser.BLLIST_IP_EXCLUDED_ENABLE = false
parser.BLLIST_IP_FILTER = false
parser.BLLIST_IP_LIMIT = 0
parser.BLLIST_GR_EXCLUDED_NETS_PATTERNS = {}

local valid = {"0.0.0.0", "255.255.255.255", "1.2.3.4/0", "1.2.3.4/32"}
local invalid = {"300.1.1.1", "1.2.3.256", "01.2.3.4", "1.2.3.4/33", "1.2.3.4/99", "1.2.3.4/033", "1.2.3.4/000"}
for _, value in ipairs(valid) do parser:ip_value_processing(value) end
for _, value in ipairs(invalid) do parser:ip_value_processing(value) end
for _, value in ipairs(valid) do
    assert(parser.ip_table[value] or parser.cidr_table[value], value)
end
for _, value in ipairs(invalid) do
    assert(not parser.ip_table[value] and not parser.cidr_table[value], value)
end
print("PASS lua-ipv4-and-cidr-validation")

local threshold = Parser:new()
threshold.BLLIST_MIN_ENTRIES = 1
threshold.ip_count = 1
threshold.download_files = function() return true end
assert(threshold:run() == 0)
threshold.ip_count = 0
assert(threshold:run() == 2)
print("PASS lua-equal-minimum-threshold")
