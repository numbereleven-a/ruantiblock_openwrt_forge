#!/usr/bin/env python3
"""Exercise the packaged Python parser without network access."""

import importlib.util
from pathlib import Path
import sys


sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[1]
source = root / "ruantiblock-mod-py/files/usr/libexec/ruantiblock/ruab_parser.py"
spec = importlib.util.spec_from_file_location("ruab_parser", source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

parser = module.BlackListParser()
parser.BLLIST_IP_EXCLUDED_ENABLE = False
parser.BLLIST_IP_FILTER = False
parser.BLLIST_IP_LIMIT = 0
parser.BLLIST_GR_EXCLUDED_NETS_PATTERNS = set()

valid = ("0.0.0.0", "255.255.255.255", "1.2.3.4/0", "1.2.3.4/32", "1.2.3.4/24")
expected = ("0.0.0.0", "255.255.255.255", "0.0.0.0/0", "1.2.3.4/32", "1.2.3.0/24")
invalid = ("300.1.1.1", "1.2.3.256", "01.2.3.4", "1.2.3.4/33", "1.2.3.4/99", "1.2.3.4/033", "1.2.3.4/000")
for value in valid + invalid:
    parser.ip_value_processing(value)

for value in expected:
    assert value in parser.ip_dict or value in parser.cidr_set, value
for value in invalid:
    assert value not in parser.ip_dict and value not in parser.cidr_set, value
print("PASS python-ipv4-and-cidr-validation")

nets = {"1.2.0.5/24", "1.2.1.9/24"}
parser_net = module.BlackListParser()
parser_net.BLLIST_IP_EXCLUDED_ENABLE = False
parser_net.BLLIST_IP_FILTER = False
for value in nets:
    parser_net.ip_value_processing(value)
summarized = [n.with_prefixlen for n in module.Summarize.summarize_nets(parser_net.cidr_set)]
assert summarized == ["1.2.0.0/23"], summarized
print("PASS python-nonstrict-cidr-summarize")

threshold = module.BlackListParser()
threshold.BLLIST_MIN_ENTRIES = 1
threshold.BLLIST_FQDN_FILTER_PATTERNS = []
threshold.BLLIST_IP_FILTER_PATTERNS = []
threshold.parser_func = lambda: threshold.ip_dict.update({"203.0.113.7": "203.0.113."})
assert threshold.run() == 0
print("PASS python-equal-minimum-threshold")

# Duplicate FQDNs and removed subdomains must not inflate SLD collapse counts.
module.Config.BLLIST_SD_LIMIT = 3
module.Config.BLLIST_STRIP_WWW = 1
module.Config.BLLIST_FQDN_FILTER = 0
module.Config.BLLIST_FQDN_EXCLUDED_ENABLE = 0
module.Config.BLLIST_ENABLE_IDN = 1
module.Config.BLLIST_CIDR_EXCLUDED_ENABLE = 0
module.Config.BLLIST_IP_LIMIT = 0
module.Config.BLLIST_SUMMARIZE_IP = 0
module.Config.BLLIST_SUMMARIZE_CIDR = 0
dup = module.BlackListParser()
for _ in range(4):
    dup.fqdn_value_processing("only-one.example.com")
oc_dup = module.OptimizeConfig([dup])
oc_dup.optimize()
assert oc_dup.fqdn_dict == {"only-one.example.com"}, oc_dup.fqdn_dict
print("PASS python-duplicate-fqdn-no-false-collapse")

capped = module.BlackListParser()
for d in ("a.example.com", "b.example.com", "sub.a.example.com", "c.example.com", "d.example.com"):
    capped.fqdn_value_processing(d)
oc_cap = module.OptimizeConfig([capped])
oc_cap.optimize()
assert oc_cap.fqdn_dict == {"example.com"}, oc_cap.fqdn_dict
print("PASS python-capped-sld-collapses-without-loss")

module.Config.BLLIST_IP_EXCLUDED_ENABLE = 1
module.Config.BLLIST_IP_EXCLUDED_ITEMS = {"10.0.0.0/24"}
module.Config.BLLIST_IP_FILTER = 0
excl_p = module.BlackListParser()
excl_p.ip_value_processing("10.0.0.5/24")
assert "10.0.0.0/24" not in excl_p.cidr_set, excl_p.cidr_set
module.Config.BLLIST_IP_EXCLUDED_ENABLE = 0
print("PASS python-normalized-cidr-honors-ip-excluded")

bad_p = module.BlackListParser()
for bad in ("a.*.example.com", "sub*1.example.com", "foo..example.com", "-bad.example.com", "bad-.example.com"):
    rejected = False
    try:
        bad_p.fqdn_value_processing(bad)
    except module.FieldValueError:
        rejected = True
    assert rejected, bad
print("PASS python-malformed-ascii-fqdn-rejected")

module.Config._load_config({"AF_FQDN_URL": " https://a.test/1  https://a.test/2 "})
assert module.Config.AF_FQDN_URL == ["https://a.test/1", "https://a.test/2"], module.Config.AF_FQDN_URL
ips = {"1.2.3.1", "1.2.3.2", "1.2.3.3"}
list(module.Summarize.summarize_ip_ranges(ips, True))
assert all(isinstance(item, str) for item in ips), ips
print("PASS python-url-split-and-summarize-types")

module.Config.RBL_ALL_URL = ["https://example.invalid/snapshot"]
module.Config.BLLIST_ORG_EXCLUDED_ENABLE = False
rbl = module.RblHybrid()
rbl._split_entries = lambda _u: [
    '{"ips": ["203.0.113.5"], "domains": ["esc.example.com"], "name": "Org \\"Quoted\\""}'
]
rbl.parser_func()
assert "esc.example.com" in rbl.fqdn_dict, rbl.fqdn_dict
print("PASS python-rbl-key-order-and-escaped-name")
