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
