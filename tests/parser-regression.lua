-- Exercise the packaged Lua parser methods without network access.
local source_path = assert(arg[1], "parser source path is required")
local lib_dir = source_path:gsub("libexec/ruantiblock/ruab_parser%.lua$", "lib/lua")
if lib_dir ~= source_path then
    package.path = lib_dir .. "/?.lua;" .. package.path
end
local source_file = assert(io.open(source_path, "r"))
local source = source_file:read("*a")
source_file:close()
source = source:gsub("^#![^\n]*\n", "")
local marker = assert(source:find("local parsers_table =", 1, true))
package.preload["ltn12"] = function() return {} end
if not pcall(require, "bit") then
    local M = {}
    local function to32(x) x = x % 4294967296; if x >= 2147483648 then x = x - 4294967296 end; return x end
    local function tou32(x) return x % 4294967296 end
    function M.bnot(a) return to32(4294967295 - tou32(a)) end
    function M.band(a, b) a, b = tou32(a), tou32(b); local r, p = 0, 1; for _ = 1, 32 do if (a%2==1) and (b%2==1) then r=r+p end; a=math.floor(a/2); b=math.floor(b/2); p=p*2 end; return to32(r) end
    function M.bor(a, b) a, b = tou32(a), tou32(b); local r, p = 0, 1; for _ = 1, 32 do if (a%2==1) or (b%2==1) then r=r+p end; a=math.floor(a/2); b=math.floor(b/2); p=p*2 end; return to32(r) end
    function M.bxor(a, b) a, b = tou32(a), tou32(b); local r, p = 0, 1; for _ = 1, 32 do if (a%2)~=(b%2) then r=r+p end; a=math.floor(a/2); b=math.floor(b/2); p=p*2 end; return to32(r) end
    function M.lshift(a, n) return to32(tou32(a) * (2 ^ (n % 32))) end
    function M.rshift(a, n) return to32(math.floor(tou32(a) / (2 ^ (n % 32)))) end
    package.preload["bit"] = function() return M end
end
local mod = assert(loadstring(source:sub(1, marker - 1) .. "\nreturn { Config=Config, BlackListParser=BlackListParser, OptimizeConfig=OptimizeConfig, Rbl=Rbl }\n"))()
local Parser = mod.BlackListParser

local parser = Parser:new()
parser.BLLIST_IP_EXCLUDED_ENABLE = false
parser.BLLIST_IP_FILTER = false
parser.BLLIST_IP_LIMIT = 0
parser.BLLIST_GR_EXCLUDED_NETS_PATTERNS = {}

local valid = {"0.0.0.0", "255.255.255.255", "1.2.3.4/0", "1.2.3.4/32", "1.2.3.4/24"}
local expected = {"0.0.0.0", "255.255.255.255", "0.0.0.0/0", "1.2.3.4/32", "1.2.3.0/24"}
local invalid = {"300.1.1.1", "1.2.3.256", "01.2.3.4", "1.2.3.4/33", "1.2.3.4/99", "1.2.3.4/033", "1.2.3.4/000"}
for _, value in ipairs(valid) do parser:ip_value_processing(value) end
for _, value in ipairs(invalid) do parser:ip_value_processing(value) end
for _, value in ipairs(expected) do
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

local idn_guard = Parser:new()
idn_guard.BLLIST_ENABLE_IDN = true
idn_guard.BLLIST_FQDN_FILTER = false
idn_guard.BLLIST_FQDN_EXCLUDED_ENABLE = false
idn_guard.BLLIST_STRIP_WWW = false
idn_guard.convert_to_punycode = function() error("shell-metachar domain must be rejected") end
assert(idn_guard:fqdn_value_processing("bad'$(id)'.ru") == false)
assert(idn_guard:fqdn_value_processing("foo:bar.com") == false)
assert(idn_guard:fqdn_value_processing(".example.com") == false)
print("PASS lua-idn-shell-metachar-rejected")

-- Duplicate FQDNs must not inflate SLD count and collapse the parent domain.
mod.Config.BLLIST_SD_LIMIT = 3
mod.Config.BLLIST_FQDN_FILTER = false
mod.Config.BLLIST_FQDN_EXCLUDED_ENABLE = false
mod.Config.BLLIST_IP_FILTER = false
mod.Config.BLLIST_IP_EXCLUDED_ENABLE = false
mod.Config.BLLIST_CIDR_EXCLUDED_ENABLE = false
mod.Config.BLLIST_IP_LIMIT = 0
mod.Config.BLLIST_SUMMARIZE_IP = false
mod.Config.BLLIST_SUMMARIZE_CIDR = true
local dup = Parser:new()
for _ = 1, 4 do dup:fqdn_value_processing("only-one.example.com") end
assert(dup.fqdn_count == 1 and dup.sld_table["example.com"] == 1)
local oc_dup = mod.OptimizeConfig:new({ parsers_list = { dup } })
oc_dup:optimize()
assert(oc_dup.fqdn_table["only-one.example.com"] and not oc_dup.fqdn_table["example.com"])
print("PASS lua-duplicate-fqdn-no-false-collapse")

-- Capped SLD must still collapse after redundant subdomain removal so dropped domains are covered.
local capped = Parser:new()
for _, d in ipairs({"a.example.com", "b.example.com", "sub.a.example.com", "c.example.com", "d.example.com"}) do
    capped:fqdn_value_processing(d)
end
local oc_cap = mod.OptimizeConfig:new({ parsers_list = { capped } })
oc_cap:optimize()
assert(oc_cap.fqdn_table["example.com"] == true)
print("PASS lua-capped-sld-collapses-without-loss")

-- Non-strict CIDR summarization and /0 overlap via iptool.
local ok_it, it = pcall(require, "iptool")
if ok_it then
    assert(it.overlap_ip("1.2.3.4", "0.0.0.0/0") == true)
    local p_net = Parser:new()
    p_net:ip_value_processing("10.0.0.5/24 10.0.1.9/24")
    local oc_net = mod.OptimizeConfig:new({ parsers_list = { p_net } })
    oc_net:optimize()
    assert(oc_net.cidr_table["10.0.0.0/23"] == true and not oc_net.cidr_table["10.0.2.0/30"])
    print("PASS lua-nonstrict-cidr-summarize-and-slash0")
end

-- IDN hyphen-2nd-char and UTF-8 char-offset validation.
local ok_idn, idn_mod = pcall(require, "idn")
if ok_idn then
    local enc = idn_mod.encode("a-б.тест.рф")
    assert(enc == "xn--a--clc.xn--e1aybc.xn--p1ai", tostring(enc))
    assert(idn_mod.encode("я--1.рф") == "xn----1-pgd.xn--p1ai")
    assert(idn_mod.encode("ab--тест.рф") == nil)
    assert(idn_mod.encode("foo:bar.com") == nil)
    print("PASS lua-idn-label-validation")
end

-- Rublacklist JSON parsing with escaped quotes and reversed key order.
local rbl = mod.Rbl:new()
rbl:parser_func()('{"appearDate": "2025-01-01", "ips": ["203.0.113.5"], "domains": ["esc.example.com"], "name": "Org \\"Quoted\\""}')
assert(rbl.fqdn_table["esc.example.com"] ~= nil)
print("PASS lua-rbl-key-order-and-escaped-name")
