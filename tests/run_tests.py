#!/usr/bin/env python3
"""Run Rubber Ducky's tests: each test_*.lua loads the addon into a mock WoW
client (harness.lua) under Lua 5.1 and asserts on what it does.
Needs: pip install lupa"""
import glob, os, sys
import lupa.lua51 as lua51

here = os.path.dirname(os.path.abspath(__file__))
addon = os.path.dirname(here) + os.sep
failed = 0
for path in sorted(glob.glob(os.path.join(here, "test_*.lua"))):
    L = lua51.LuaRuntime()
    g = L.globals()
    g.TESTS = here + os.sep
    g.ADDON = addon
    g.QUIET = "-v" not in sys.argv
    name = os.path.basename(path)
    try:
        with open(path) as f:
            L.execute(f.read())
        print(f"ok    {name}")
    except Exception as e:
        failed += 1
        print(f"FAIL  {name}: {str(e).splitlines()[0]}")
print(f"\n{failed} failed" if failed else "\nall passed")
sys.exit(1 if failed else 0)
