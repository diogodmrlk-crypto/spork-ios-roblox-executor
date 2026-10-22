#pragma once

// roblox dumper ios | https://github.com/ra1nbolt/roblox-ios-dumper
// dumped product: RobloxPlayer 2.737.0.1581 (git hash: 7945640bedb0d287eea74611488e5b104523f232)

#include <cstddef>
#include <cstdint>

namespace offsets {
    namespace luau {
        inline constexpr std::uintptr_t luaL_argerror = 0x4040e7c;
        inline constexpr std::uintptr_t luaL_error = 0x4040f4c;
        inline constexpr std::uintptr_t luaL_sandboxthread = 0x17f90b4;
        inline constexpr std::uintptr_t luaL_typeerror = 0x4040f98;
        inline constexpr std::uintptr_t luaL_typename = 0x40419d8;
        inline constexpr std::uintptr_t luaO_nilobject = 0x4fec9a8;
        inline constexpr std::uintptr_t lua_absindex = 0x403c860;
        inline constexpr std::uintptr_t lua_breakpoint = 0x404a998;
        inline constexpr std::uintptr_t lua_call = 0x403f5d0;
        inline constexpr std::uintptr_t lua_createtable = 0x403ea78;
        inline constexpr std::uintptr_t lua_encodepointer = 0x4040538;
        inline constexpr std::uintptr_t lua_gc = 0x403f81c;
        inline constexpr std::uintptr_t lua_getfield = 0x403e58c;
        inline constexpr std::uintptr_t lua_getmetatable = 0x403ec8c;
        inline constexpr std::uintptr_t lua_gettop = 0x403c890;
        inline constexpr std::uintptr_t lua_namecallatom = 0x403d7d8;
        inline constexpr std::uintptr_t lua_newbuffer = 0x403ffac;
        inline constexpr std::uintptr_t lua_newthread = 0x403c784;
        inline constexpr std::uintptr_t lua_newuserdatatagged = 0x403fe00;
        inline constexpr std::uintptr_t lua_pcall = 0x403f67c;
        inline constexpr std::uintptr_t lua_pushboolean = 0x403e33c;
        inline constexpr std::uintptr_t lua_pushcclosurek = 0x403e1d4;
        inline constexpr std::uintptr_t lua_pushinteger = 0x403ddd0;
        inline constexpr std::uintptr_t lua_pushlstring = 0x403dfe0;
        inline constexpr std::uintptr_t lua_pushnil = 0x403dce0;
        inline constexpr std::uintptr_t lua_pushnumber = 0x403dd4c;
        inline constexpr std::uintptr_t lua_pushstring = 0x403e0ac;
        inline constexpr std::uintptr_t lua_pushvalue = 0x403cc70;
        inline constexpr std::uintptr_t lua_ref = 0x40405e0;
        inline constexpr std::uintptr_t lua_setfield = 0x403ef74;
        inline constexpr std::uintptr_t lua_setmetatable = 0x403f3fc;
        inline constexpr std::uintptr_t lua_setreadonly = 0x403eb44;
        inline constexpr std::uintptr_t lua_setsafeenv = 0x403ec18;
        inline constexpr std::uintptr_t lua_settop = 0x403c8a4;
        inline constexpr std::uintptr_t lua_status = 0x403f7b0;
        inline constexpr std::uintptr_t lua_toboolean = 0x403d3bc;
        inline constexpr std::uintptr_t lua_tolstring = 0x403d4cc;
        inline constexpr std::uintptr_t lua_type = 0x403cd50;
        inline constexpr std::uintptr_t lua_unref = 0x4040700;
        inline constexpr std::uintptr_t luau_execute = 0x405d7f0;
        inline constexpr std::uintptr_t luau_load = 0x4066ac0;
        inline constexpr std::uintptr_t pseudo2addr = 0x4040d94;
    } // namespace luau

    namespace roblox {
        inline constexpr std::uintptr_t firemouseclick = 0x20ffcbc;
        inline constexpr std::uintptr_t fireproximityprompt = 0x242ae34;
        inline constexpr std::uintptr_t firerightmouseclick = 0x20ffe64;
        inline constexpr std::uintptr_t firetouchinterest = 0x2c54ef0;
        inline constexpr std::uintptr_t get_extra_space = 0x7bae20;
        inline constexpr std::uintptr_t get_global_state = 0x17bf860;
        inline constexpr std::uintptr_t get_instance_capabilities = 0x4021014;
        inline constexpr std::uintptr_t get_scriptcontext = 0x17bd584;
        inline constexpr std::uintptr_t get_thread_capabilities = 0x17bb698;
        inline constexpr std::uintptr_t ktable = 0x6948cb0;
        inline constexpr std::uintptr_t opcode_lookup_table = 0x506d2d0;
        inline constexpr std::uintptr_t print = 0x4088270;
        inline constexpr std::uintptr_t pushinstance = 0x17794a8;
        inline constexpr std::uintptr_t spawn = 0x17a52c8;
        inline constexpr std::uintptr_t taskscheduler = 0x668ef70;
    } // namespace roblox
} // namespace offsets

namespace fields {
    namespace GCheader {
        inline constexpr std::ptrdiff_t marked = 0x2;
        inline constexpr std::ptrdiff_t memcat = 0x0;
        inline constexpr std::ptrdiff_t sizeof_ = 0x3;
        inline constexpr std::ptrdiff_t tt = 0x1;
    } // namespace GCheader

    namespace lua_State {
        inline constexpr std::ptrdiff_t activememcat = 0x4;
        inline constexpr std::ptrdiff_t base = 0x58;
        inline constexpr std::ptrdiff_t baseCcalls = 0xa;
        inline constexpr std::ptrdiff_t base_ci = 0x20;
        inline constexpr std::ptrdiff_t cachedslot = 0xc;
        inline constexpr std::ptrdiff_t ci = 0x50;
        inline constexpr std::ptrdiff_t end_ci = 0x18;
        inline constexpr std::ptrdiff_t gclist = 0x28;
        inline constexpr std::ptrdiff_t global = 0x70;
        inline constexpr std::ptrdiff_t gt = 0x38;
        inline constexpr std::ptrdiff_t isactive = 0x6;
        inline constexpr std::ptrdiff_t marked = 0x2;
        inline constexpr std::ptrdiff_t memcat = 0x0;
        inline constexpr std::ptrdiff_t nCcalls = 0x8;
        inline constexpr std::ptrdiff_t namecall = 0x30;
        inline constexpr std::ptrdiff_t openupval = 0x40;
        inline constexpr std::ptrdiff_t singlestep = 0x5;
        inline constexpr std::ptrdiff_t size_ci = 0x14;
        inline constexpr std::ptrdiff_t sizeof_ = 0x80;
        inline constexpr std::ptrdiff_t stack = 0x60;
        inline constexpr std::ptrdiff_t stack_last = 0x68;
        inline constexpr std::ptrdiff_t stacksize = 0x10;
        inline constexpr std::ptrdiff_t status = 0x3;
        inline constexpr std::ptrdiff_t top = 0x78;
        inline constexpr std::ptrdiff_t tt = 0x1;
        inline constexpr std::ptrdiff_t userdata = 0x48;
    } // namespace lua_State

    namespace TValue {
        inline constexpr std::ptrdiff_t extra = 0x8;
        inline constexpr std::ptrdiff_t sizeof_ = 0x10;
        inline constexpr std::ptrdiff_t tt = 0xc;
        inline constexpr std::ptrdiff_t value = 0x0;
    } // namespace TValue

    namespace CallInfo {
        inline constexpr std::ptrdiff_t base = 0x0;
        inline constexpr std::ptrdiff_t errfunc = 0x20;
        inline constexpr std::ptrdiff_t flags = 0x2c;
        inline constexpr std::ptrdiff_t func = 0x10;
        inline constexpr std::ptrdiff_t nresults = 0x28;
        inline constexpr std::ptrdiff_t p = 0x18;
        inline constexpr std::ptrdiff_t savedpc = 0x20;
        inline constexpr std::ptrdiff_t sizeof_ = 0x30;
        inline constexpr std::ptrdiff_t top = 0x8;
    } // namespace CallInfo

    namespace Proto {
        inline constexpr std::ptrdiff_t abslineinfo = 0x70;
        inline constexpr std::ptrdiff_t bytecodeid = 0x90;
        inline constexpr std::ptrdiff_t code = 0x30;
        inline constexpr std::ptrdiff_t codeentry = 0x60;
        inline constexpr std::ptrdiff_t cost = 0xd0;
        inline constexpr std::ptrdiff_t debuginsn = 0x40;
        inline constexpr std::ptrdiff_t debugname = 0x18;
        inline constexpr std::ptrdiff_t deoptimized = 0xc8;
        inline constexpr std::ptrdiff_t execdata = 0x8;
        inline constexpr std::ptrdiff_t exectarget = 0x10;
        inline constexpr std::ptrdiff_t feedbackvec = 0xb0;
        inline constexpr std::ptrdiff_t feedbackvecsize = 0xb8;
        inline constexpr std::ptrdiff_t flags = 0x4;
        inline constexpr std::ptrdiff_t funid = 0xbc;
        inline constexpr std::ptrdiff_t gclist = 0x50;
        inline constexpr std::ptrdiff_t is_vararg = 0x7;
        inline constexpr std::ptrdiff_t k = 0x28;
        inline constexpr std::ptrdiff_t linedefined = 0x94;
        inline constexpr std::ptrdiff_t linegaplog2 = 0x9c;
        inline constexpr std::ptrdiff_t lineinfo = 0x48;
        inline constexpr std::ptrdiff_t locvars = 0x78;
        inline constexpr std::ptrdiff_t marked = 0x2;
        inline constexpr std::ptrdiff_t maxstacksize = 0x3;
        inline constexpr std::ptrdiff_t memcat = 0x0;
        inline constexpr std::ptrdiff_t numparams = 0x5;
        inline constexpr std::ptrdiff_t nups = 0x6;
        inline constexpr std::ptrdiff_t optimized = 0xc0;
        inline constexpr std::ptrdiff_t p = 0x80;
        inline constexpr std::ptrdiff_t sizecode = 0x98;
        inline constexpr std::ptrdiff_t sizek = 0xa4;
        inline constexpr std::ptrdiff_t sizelineinfo = 0x8c;
        inline constexpr std::ptrdiff_t sizelocvars = 0xa0;
        inline constexpr std::ptrdiff_t sizeof_ = 0xd8;
        inline constexpr std::ptrdiff_t sizep = 0xac;
        inline constexpr std::ptrdiff_t sizetypeinfo = 0xa8;
        inline constexpr std::ptrdiff_t sizeupvalues = 0x88;
        inline constexpr std::ptrdiff_t source = 0x68;
        inline constexpr std::ptrdiff_t tt = 0x1;
        inline constexpr std::ptrdiff_t typeinfo = 0x38;
        inline constexpr std::ptrdiff_t upvalues = 0x58;
        inline constexpr std::ptrdiff_t userdata = 0x20;
    } // namespace Proto

    namespace LuaTable {
        inline constexpr std::ptrdiff_t aboundary = 0xc;
        inline constexpr std::ptrdiff_t array = 0x20;
        inline constexpr std::ptrdiff_t gclist = 0x18;
        inline constexpr std::ptrdiff_t lastfree = 0xc;
        inline constexpr std::ptrdiff_t lsizenode = 0x3;
        inline constexpr std::ptrdiff_t marked = 0x2;
        inline constexpr std::ptrdiff_t memcat = 0x0;
        inline constexpr std::ptrdiff_t metatable = 0x10;
        inline constexpr std::ptrdiff_t node = 0x28;
        inline constexpr std::ptrdiff_t nodemask8 = 0x4;
        inline constexpr std::ptrdiff_t readonly = 0x5;
        inline constexpr std::ptrdiff_t safeenv = 0x7;
        inline constexpr std::ptrdiff_t sizearray = 0x8;
        inline constexpr std::ptrdiff_t sizeof_ = 0x30;
        inline constexpr std::ptrdiff_t tmcache = 0x6;
        inline constexpr std::ptrdiff_t tt = 0x1;
    } // namespace LuaTable

    namespace TKey {
        inline constexpr std::ptrdiff_t extra = 0x8;
        inline constexpr std::ptrdiff_t next = 0xc;
        inline constexpr std::ptrdiff_t sizeof_ = 0x10;
        inline constexpr std::ptrdiff_t tt = 0xc;
        inline constexpr std::ptrdiff_t value = 0x0;
    } // namespace TKey

    namespace LuaNode {
        inline constexpr std::ptrdiff_t key = 0x10;
        inline constexpr std::ptrdiff_t sizeof_ = 0x20;
        inline constexpr std::ptrdiff_t val = 0x0;
    } // namespace LuaNode

    namespace Closure {
        inline constexpr std::ptrdiff_t env = 0x10;
        inline constexpr std::ptrdiff_t gclist = 0x8;
        inline constexpr std::ptrdiff_t isC = 0x6;
        inline constexpr std::ptrdiff_t marked = 0x2;
        inline constexpr std::ptrdiff_t memcat = 0x0;
        inline constexpr std::ptrdiff_t nupvalues = 0x4;
        inline constexpr std::ptrdiff_t preload = 0x5;
        inline constexpr std::ptrdiff_t sizeof_ = 0x40;
        inline constexpr std::ptrdiff_t stacksize = 0x3;
        inline constexpr std::ptrdiff_t tt = 0x1;

        namespace c {
            inline constexpr std::ptrdiff_t cont = 0x20;
            inline constexpr std::ptrdiff_t debugname = 0x18;
            inline constexpr std::ptrdiff_t f = 0x28;
            inline constexpr std::ptrdiff_t upvals = 0x30;
        } // namespace c

        namespace l {
            inline constexpr std::ptrdiff_t p = 0x18;
            inline constexpr std::ptrdiff_t uprefs = 0x20;
        } // namespace l
    } // namespace Closure

    namespace TString {
        inline constexpr std::ptrdiff_t atom = 0x4;
        inline constexpr std::ptrdiff_t data = 0x18;
        inline constexpr std::ptrdiff_t hash = 0x10;
        inline constexpr std::ptrdiff_t len = 0x14;
        inline constexpr std::ptrdiff_t marked = 0x2;
        inline constexpr std::ptrdiff_t memcat = 0x0;
        inline constexpr std::ptrdiff_t next = 0x8;
        inline constexpr std::ptrdiff_t sizeof_ = 0x20;
        inline constexpr std::ptrdiff_t tt = 0x1;
    } // namespace TString

    namespace stringtable {
        inline constexpr std::ptrdiff_t hash = 0x8;
        inline constexpr std::ptrdiff_t nuse = 0x4;
        inline constexpr std::ptrdiff_t size = 0x0;
        inline constexpr std::ptrdiff_t sizeof_ = 0x10;
    } // namespace stringtable

    namespace global_State {
        inline constexpr std::ptrdiff_t GCthreshold = 0x0;
        inline constexpr std::ptrdiff_t allgcopages = 0x2e0;
        inline constexpr std::ptrdiff_t allpages = 0x2d8;
        inline constexpr std::ptrdiff_t builtinPcall = 0x4870;
        inline constexpr std::ptrdiff_t builtinXpcall = 0x4878;
        inline constexpr std::ptrdiff_t cb = 0x4f8;
        inline constexpr std::ptrdiff_t currentwhite = 0x30;
        inline constexpr std::ptrdiff_t ecb = 0x568;
        inline constexpr std::ptrdiff_t ecbdata = 0x5b0;
        inline constexpr std::ptrdiff_t embeddergc = 0x4058;
        inline constexpr std::ptrdiff_t errorjmp = 0x4d0;
        inline constexpr std::ptrdiff_t frealloc = 0x10;
        inline constexpr std::ptrdiff_t freegcopages = 0x198;
        inline constexpr std::ptrdiff_t freepages = 0x58;
        inline constexpr std::ptrdiff_t gcgoal = 0x34;
        inline constexpr std::ptrdiff_t gcmetrics = 0x4988;
        inline constexpr std::ptrdiff_t gcstate = 0x31;
        inline constexpr std::ptrdiff_t gcstats = 0x48c8;
        inline constexpr std::ptrdiff_t gcstepmul = 0x38;
        inline constexpr std::ptrdiff_t gcstepsize = 0x3c;
        inline constexpr std::ptrdiff_t gray = 0x40;
        inline constexpr std::ptrdiff_t grayagain = 0x48;
        inline constexpr std::ptrdiff_t lastprotoid = 0x4980;
        inline constexpr std::ptrdiff_t lightuserdataname = 0x4060;
        inline constexpr std::ptrdiff_t mainthread = 0x318;
        inline constexpr std::ptrdiff_t memcatbytes = 0x2c40;
        inline constexpr std::ptrdiff_t mt = 0x438;
        inline constexpr std::ptrdiff_t pseudotemp = 0x4a8;
        inline constexpr std::ptrdiff_t ptrencactive = 0x48c0;
        inline constexpr std::ptrdiff_t ptrenckey = 0x4d8;
        inline constexpr std::ptrdiff_t ptrenckeynew = 0x4880;
        inline constexpr std::ptrdiff_t registry = 0x4b8;
        inline constexpr std::ptrdiff_t registryfree = 0x4c8;
        inline constexpr std::ptrdiff_t rngstate = 0x560;
        inline constexpr std::ptrdiff_t sizeof_ = 0x4b60;
        inline constexpr std::ptrdiff_t strt = 0x20;
        inline constexpr std::ptrdiff_t sweepgcopage = 0x310;
        inline constexpr std::ptrdiff_t tmname = 0x320;
        inline constexpr std::ptrdiff_t totalbytes = 0x8;
        inline constexpr std::ptrdiff_t ttname = 0x3c8;
        inline constexpr std::ptrdiff_t ud = 0x18;
        inline constexpr std::ptrdiff_t udatadirect = 0x7b0;
        inline constexpr std::ptrdiff_t udatadirectfields = 0x4460;
        inline constexpr std::ptrdiff_t udatagc = 0x3440;
        inline constexpr std::ptrdiff_t udatamark = 0x3840;
        inline constexpr std::ptrdiff_t udatamt = 0x3c40;
        inline constexpr std::ptrdiff_t uvhead = 0x2e8;
        inline constexpr std::ptrdiff_t weak = 0x50;
        inline constexpr std::ptrdiff_t weakregistry = 0x4040;
        inline constexpr std::ptrdiff_t weakregistryfree = 0x4050;
        inline constexpr std::ptrdiff_t weakregistrytop = 0x4054;
    } // namespace global_State

    namespace Udata {
        inline constexpr std::ptrdiff_t data = 0x10;
        inline constexpr std::ptrdiff_t len = 0x4;
        inline constexpr std::ptrdiff_t marked = 0x2;
        inline constexpr std::ptrdiff_t memcat = 0x0;
        inline constexpr std::ptrdiff_t metatable = 0x8;
        inline constexpr std::ptrdiff_t sizeof_ = 0x18;
        inline constexpr std::ptrdiff_t tag = 0x3;
        inline constexpr std::ptrdiff_t tt = 0x1;
    } // namespace Udata

    namespace Buffer {
        inline constexpr std::ptrdiff_t data = 0x8;
        inline constexpr std::ptrdiff_t len = 0x4;
        inline constexpr std::ptrdiff_t marked = 0x2;
        inline constexpr std::ptrdiff_t memcat = 0x0;
        inline constexpr std::ptrdiff_t sizeof_ = 0x10;
        inline constexpr std::ptrdiff_t tt = 0x1;
    } // namespace Buffer

    namespace RobloxExtraSpace {
        inline constexpr std::ptrdiff_t capabilities = 0x40;
    } // namespace RobloxExtraSpace

    namespace UpVal {
        inline constexpr std::ptrdiff_t marked = 0x2;
        inline constexpr std::ptrdiff_t markedopen = 0x3;
        inline constexpr std::ptrdiff_t memcat = 0x0;
        inline constexpr std::ptrdiff_t sizeof_ = 0x28;
        inline constexpr std::ptrdiff_t tt = 0x1;
        inline constexpr std::ptrdiff_t v = 0x8;
        inline constexpr std::ptrdiff_t value = 0x10;

        namespace open {
            inline constexpr std::ptrdiff_t next = 0x18;
            inline constexpr std::ptrdiff_t prev = 0x10;
            inline constexpr std::ptrdiff_t threadnext = 0x20;
        } // namespace open
    } // namespace UpVal

    namespace TaskScheduler {
        inline constexpr std::ptrdiff_t jobs_end = 0xd8;
        inline constexpr std::ptrdiff_t jobs_start = 0xd0;
    } // namespace TaskScheduler

    namespace Job {
        inline constexpr std::ptrdiff_t name = 0x18;
        inline constexpr std::ptrdiff_t script_context = 0x1a8;
    } // namespace Job

    namespace RobloxInstance {
        inline constexpr std::ptrdiff_t children = 0x78;
        inline constexpr std::ptrdiff_t class_descriptor = 0x18;
        inline constexpr std::ptrdiff_t name = 0x70;
        inline constexpr std::ptrdiff_t parent = 0x68;
        inline constexpr std::ptrdiff_t vtable = 0x0;
    } // namespace RobloxInstance

} // namespace fields
