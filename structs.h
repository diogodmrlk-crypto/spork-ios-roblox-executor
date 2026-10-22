#pragma once

// roblox dumper ios | https://github.com/ra1nbolt/roblox-ios-dumper
// dumped product: RobloxPlayer 2.737.0.1581 (git hash: 7945640bedb0d287eea74611488e5b104523f232)
// Field order and offsets were discovered at runtime; names and types follow Luau.
// Luau layouts contain no explicit padding; Roblox overlays use _pad members.

#include <cstddef>
#include <cstdint>

namespace structures {

union GCObject;
struct lua_State;
struct Proto;
struct TString;
struct LuaTable;
struct TKey;
struct LuaNode;
struct UpVal;
struct Closure;
struct stringtable;
struct global_State;
struct RobloxExtraSpace;
struct RobloxInstance;
struct RobloxString;
struct lua_Page;
struct lua_jmpbuf;
struct lua_Debug;
struct LocVar;
struct FeedbackVectorSlot;
using Instruction = uint32_t;
using lua_CFunction = int (*)(lua_State* L);
using lua_Continuation = int (*)(lua_State* L, int status);
using lua_Alloc = void* (*)(void* ud, void* ptr, size_t osize, size_t nsize);

using lua_UserdataMark = void (*)(lua_State* L, void* ud);
using lua_EmbedderMark = void (*)(lua_State* L, int ref);
using lua_EmbedderGc = void (*)(lua_State* L, lua_EmbedderMark markref);
using lua_UserdataDirectAccess = void (*)(lua_State* L, void* data, int atom, uint16_t* cachedslot, int utag);
using lua_UserdataDirectNamecall = int (*)(lua_State* L, void* data, int atom, uint16_t* cachedslot, int utag);

// overall confidence: high | evidence: release-matched Luau ABI
union Value {
    GCObject* gc; // offset: 0x0 | field confidence: high | evidence: upstream Luau Value union
    void* p; // offset: 0x0 | field confidence: high | evidence: upstream Luau Value union
    double n; // offset: 0x0 | field confidence: high | evidence: upstream Luau Value union
    int b; // offset: 0x0 | field confidence: high | evidence: upstream Luau Value union
    int64_t l; // offset: 0x0 | field confidence: high | evidence: upstream Luau Value union
    float v[2]; // offset: 0x0 | field confidence: high | evidence: upstream Luau Value union
};

// overall confidence: high | fields: 3 high, 0 medium, 0 low
struct GCheader {
    uint8_t memcat; // offset: 0x0 | field confidence: high | evidence: field identity inherited from controlled lua_State CommonHeader probe
    uint8_t tt; // offset: 0x1 | field confidence: high | evidence: field identity inherited from controlled lua_State CommonHeader probe
    uint8_t marked; // offset: 0x2 | field confidence: high | evidence: field identity inherited from controlled lua_State CommonHeader probe
};
static_assert(offsetof(GCheader, memcat) == 0x0);
static_assert(offsetof(GCheader, tt) == 0x1);
static_assert(offsetof(GCheader, marked) == 0x2);
static_assert(sizeof(GCheader) == 0x3);

// overall confidence: medium | fields: 2 high, 1 medium, 0 low
struct TValue {
    Value value; // offset: 0x0 | field confidence: high | evidence: controlled values and GC object correlation
    int extra[1]; // offset: 0x8 | field confidence: medium | evidence: remaining verified TValue integer lane
    int tt; // offset: 0xc | field confidence: high | evidence: typed pushes and runtime tag correlation
};
static_assert(offsetof(TValue, value) == 0x0);
static_assert(offsetof(TValue, extra) == 0x8);
static_assert(offsetof(TValue, tt) == 0xc);
static_assert(sizeof(TValue) == 0x10);

using StkId = TValue*;

// overall confidence: high | fields: 4 high, 0 medium, 0 low
struct TKey {
    Value value; // offset: 0x0 | field confidence: high | evidence: controlled hash keys and TValue payloads
    int extra[1]; // offset: 0x8 | field confidence: high | evidence: controlled hash keys and TValue payloads
    unsigned tt : 4; // offset: 0xc | field confidence: high | evidence: controlled hash keys and TValue payloads
    int next : 28; // offset: 0xc | field confidence: high | evidence: controlled hash keys and TValue payloads
};
static_assert(sizeof(TKey) == 0x10);

// overall confidence: high | fields: 2 high, 0 medium, 0 low
struct LuaNode {
    TValue val; // offset: 0x0 | field confidence: high | evidence: controlled hash keys and TValue payloads
    TKey key; // offset: 0x10 | field confidence: high | evidence: controlled hash keys and TValue payloads
};
static_assert(offsetof(LuaNode, val) == 0x0);
static_assert(offsetof(LuaNode, key) == 0x10);
static_assert(sizeof(LuaNode) == 0x20);

// overall confidence: medium | fields: 5 high, 3 medium, 0 low
struct TString {
    uint8_t memcat; // offset: 0x0 | field confidence: medium | evidence: runtime structural validation
    uint8_t tt; // offset: 0x1 | field confidence: medium | evidence: runtime structural validation
    uint8_t marked; // offset: 0x2 | field confidence: medium | evidence: runtime structural validation
    int16_t atom; // offset: 0x4 | field confidence: high | evidence: ATOM_UNDEF on two fresh interned strings
    TString* next; // offset: 0x8 | field confidence: high | evidence: controlled string-table bucket collision
    unsigned int hash; // offset: 0x10 | field confidence: high | evidence: two controlled strings and Luau hash oracle
    unsigned int len; // offset: 0x14 | field confidence: high | evidence: two controlled strings and Luau hash oracle
    char data[1]; // offset: 0x18 | field confidence: high | evidence: two controlled strings and Luau hash oracle
};
static_assert(offsetof(TString, memcat) == 0x0);
static_assert(offsetof(TString, tt) == 0x1);
static_assert(offsetof(TString, marked) == 0x2);
static_assert(offsetof(TString, atom) == 0x4);
static_assert(offsetof(TString, next) == 0x8);
static_assert(offsetof(TString, hash) == 0x10);
static_assert(offsetof(TString, len) == 0x14);
static_assert(offsetof(TString, data) == 0x18);
static_assert(sizeof(TString) == 0x20);

// overall confidence: medium | fields: 9 high, 6 medium, 0 low
struct LuaTable {
    uint8_t memcat; // offset: 0x0 | field confidence: medium | evidence: runtime structural validation
    uint8_t tt; // offset: 0x1 | field confidence: medium | evidence: runtime structural validation
    uint8_t marked; // offset: 0x2 | field confidence: medium | evidence: runtime structural validation
    uint8_t lsizenode; // offset: 0x3 | field confidence: high | evidence: controlled lua_createtable capacities and contents
    uint8_t nodemask8; // offset: 0x4 | field confidence: high | evidence: controlled lua_createtable capacities and contents
    uint8_t readonly; // offset: 0x5 | field confidence: high | evidence: controlled API mutation and readback oracle
    uint8_t tmcache; // offset: 0x6 | field confidence: medium | evidence: runtime structural validation
    uint8_t safeenv; // offset: 0x7 | field confidence: high | evidence: controlled API mutation and readback oracle
    int sizearray; // offset: 0x8 | field confidence: high | evidence: controlled lua_createtable capacities and contents
    union {
        int lastfree; // offset: 0xc | field confidence: high | evidence: controlled lua_createtable capacities and contents
        int aboundary; // offset: 0xc | field confidence: medium | evidence: runtime structural validation
    };
    LuaTable* metatable; // offset: 0x10 | field confidence: high | evidence: controlled API mutation and readback oracle
    GCObject* gclist; // offset: 0x18 | field confidence: medium | evidence: runtime structural validation
    TValue* array; // offset: 0x20 | field confidence: high | evidence: controlled lua_createtable capacities and contents
    LuaNode* node; // offset: 0x28 | field confidence: high | evidence: controlled lua_createtable capacities and contents
};
static_assert(offsetof(LuaTable, memcat) == 0x0);
static_assert(offsetof(LuaTable, tt) == 0x1);
static_assert(offsetof(LuaTable, marked) == 0x2);
static_assert(offsetof(LuaTable, lsizenode) == 0x3);
static_assert(offsetof(LuaTable, nodemask8) == 0x4);
static_assert(offsetof(LuaTable, readonly) == 0x5);
static_assert(offsetof(LuaTable, tmcache) == 0x6);
static_assert(offsetof(LuaTable, safeenv) == 0x7);
static_assert(offsetof(LuaTable, sizearray) == 0x8);
static_assert(offsetof(LuaTable, aboundary) == 0xc);
static_assert(offsetof(LuaTable, lastfree) == 0xc);
static_assert(offsetof(LuaTable, metatable) == 0x10);
static_assert(offsetof(LuaTable, gclist) == 0x18);
static_assert(offsetof(LuaTable, array) == 0x20);
static_assert(offsetof(LuaTable, node) == 0x28);
static_assert(sizeof(LuaTable) == 0x30);

// overall confidence: high | fields: 7 high, 0 medium, 0 low
struct Udata {
    uint8_t memcat; // offset: 0x0 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    uint8_t tt; // offset: 0x1 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    uint8_t marked; // offset: 0x2 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    uint8_t tag; // offset: 0x3 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    int len; // offset: 0x4 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    LuaTable* metatable; // offset: 0x8 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    alignas(8) char data[1]; // offset: 0x10 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
};
static_assert(offsetof(Udata, memcat) == 0x0);
static_assert(offsetof(Udata, tt) == 0x1);
static_assert(offsetof(Udata, marked) == 0x2);
static_assert(offsetof(Udata, tag) == 0x3);
static_assert(offsetof(Udata, len) == 0x4);
static_assert(offsetof(Udata, metatable) == 0x8);
static_assert(offsetof(Udata, data) == 0x10);
static_assert(sizeof(Udata) == 0x18);

// overall confidence: high | fields: 5 high, 0 medium, 0 low
struct Buffer {
    uint8_t memcat; // offset: 0x0 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    uint8_t tt; // offset: 0x1 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    uint8_t marked; // offset: 0x2 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    unsigned int len; // offset: 0x4 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
    alignas(8) char data[1]; // offset: 0x8 | field confidence: high | evidence: two controlled allocations with distinct size/tag payloads
};
static_assert(offsetof(Buffer, memcat) == 0x0);
static_assert(offsetof(Buffer, tt) == 0x1);
static_assert(offsetof(Buffer, marked) == 0x2);
static_assert(offsetof(Buffer, len) == 0x4);
static_assert(offsetof(Buffer, data) == 0x8);
static_assert(sizeof(Buffer) == 0x10);

// overall confidence: high | fields: 3 high, 0 medium, 0 low
struct stringtable {
    int size; // offset: 0x0 | field confidence: high | evidence: fresh TString hash-bucket backlink
    uint32_t nuse; // offset: 0x4 | field confidence: high | evidence: fresh TString hash-bucket backlink
    TString** hash; // offset: 0x8 | field confidence: high | evidence: fresh TString hash-bucket backlink
};
static_assert(offsetof(stringtable, size) == 0x0);
static_assert(offsetof(stringtable, nuse) == 0x4);
static_assert(offsetof(stringtable, hash) == 0x8);
static_assert(sizeof(stringtable) == 0x10);

// overall confidence: medium | fields: 4 high, 4 medium, 0 low
struct CallInfo {
    StkId base; // offset: 0x0 | field confidence: high | evidence: live stack and frame invariants
    StkId top; // offset: 0x8 | field confidence: high | evidence: live stack and frame invariants
    StkId func; // offset: 0x10 | field confidence: high | evidence: live stack and frame invariants
    Proto* p; // offset: 0x18 | field confidence: high | evidence: Closure to Proto identity
    union {
        const Instruction* savedpc; // offset: 0x20 | field confidence: medium | evidence: remaining upstream union slot after pointer and scalar validation
        int errfunc; // offset: 0x20 | field confidence: medium | evidence: upstream union alias with savedpc
    };
    int nresults; // offset: 0x28 | field confidence: medium | evidence: range and adjacency checks across live frames
    unsigned int flags; // offset: 0x2c | field confidence: medium | evidence: range and adjacency checks across live frames
};
static_assert(offsetof(CallInfo, base) == 0x0);
static_assert(offsetof(CallInfo, top) == 0x8);
static_assert(offsetof(CallInfo, func) == 0x10);
static_assert(offsetof(CallInfo, p) == 0x18);
static_assert(offsetof(CallInfo, savedpc) == 0x20);
static_assert(offsetof(CallInfo, errfunc) == 0x20);
static_assert(offsetof(CallInfo, nresults) == 0x28);
static_assert(offsetof(CallInfo, flags) == 0x2c);
static_assert(sizeof(CallInfo) == 0x30);

// overall confidence: high | fields: 9 high, 0 medium, 0 low
struct UpVal {
    uint8_t memcat; // offset: 0x0 | field confidence: high | evidence: two controlled open upvalues followed by luaF_close
    uint8_t tt; // offset: 0x1 | field confidence: high | evidence: two controlled open upvalues followed by luaF_close
    uint8_t marked; // offset: 0x2 | field confidence: high | evidence: two controlled open upvalues followed by luaF_close
    uint8_t markedopen; // offset: 0x3 | field confidence: high | evidence: two controlled open upvalues followed by luaF_close
    TValue* v; // offset: 0x8 | field confidence: high | evidence: two controlled open upvalues followed by luaF_close
    union {
        TValue value; // offset: 0x10 | field confidence: high | evidence: two controlled open upvalues followed by luaF_close
        struct {
            UpVal* prev; // offset: 0x10 | field confidence: high | evidence: two controlled open upvalues followed by luaF_close
            UpVal* next; // offset: 0x18 | field confidence: high | evidence: two controlled open upvalues followed by luaF_close
            UpVal* threadnext; // offset: 0x20 | field confidence: high | evidence: two controlled open upvalues followed by luaF_close
        } open;
    } u;
};
static_assert(sizeof(UpVal) == 0x28);

// overall confidence: medium | fields: 35 high, 5 medium, 0 low
struct Proto {
    uint8_t memcat; // offset: 0x0 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    uint8_t tt; // offset: 0x1 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    uint8_t marked; // offset: 0x2 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    uint8_t maxstacksize; // offset: 0x3 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    uint8_t flags; // offset: 0x4 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    uint8_t numparams; // offset: 0x5 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    uint8_t nups; // offset: 0x6 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    uint8_t is_vararg; // offset: 0x7 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    void* execdata; // offset: 0x8 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    uintptr_t exectarget; // offset: 0x10 | field confidence: medium | evidence: runtime-proved neighbouring fields and upstream Luau adjacency invariant
    TString* debugname; // offset: 0x18 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    void* userdata; // offset: 0x20 | field confidence: medium | evidence: runtime-proved neighbouring fields and upstream Luau adjacency invariant
    TValue* k; // offset: 0x28 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    Instruction* code; // offset: 0x30 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    uint8_t* typeinfo; // offset: 0x38 | field confidence: medium | evidence: runtime-proved neighbouring fields and upstream Luau adjacency invariant
    uint8_t* debuginsn; // offset: 0x40 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    uint8_t* lineinfo; // offset: 0x48 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    GCObject* gclist; // offset: 0x50 | field confidence: medium | evidence: runtime-proved neighbouring fields and upstream Luau adjacency invariant
    TString** upvalues; // offset: 0x58 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    const Instruction* codeentry; // offset: 0x60 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    TString* source; // offset: 0x68 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    int* abslineinfo; // offset: 0x70 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    LocVar* locvars; // offset: 0x78 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    Proto** p; // offset: 0x80 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    int sizeupvalues; // offset: 0x88 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    int sizelineinfo; // offset: 0x8c | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    int bytecodeid; // offset: 0x90 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    int linedefined; // offset: 0x94 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    int sizecode; // offset: 0x98 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    int linegaplog2; // offset: 0x9c | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    int sizelocvars; // offset: 0xa0 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    int sizek; // offset: 0xa4 | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    int sizetypeinfo; // offset: 0xa8 | field confidence: medium | evidence: runtime-proved neighbouring fields and upstream Luau adjacency invariant
    int sizep; // offset: 0xac | field confidence: high | evidence: captured bytecode metadata correlated across live Proto objects
    FeedbackVectorSlot* feedbackvec; // offset: 0xb0 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    uint32_t feedbackvecsize; // offset: 0xb8 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    uint32_t funid; // offset: 0xbc | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    Proto* optimized; // offset: 0xc0 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    Proto* deoptimized; // offset: 0xc8 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
    uint64_t cost; // offset: 0xd0 | field confidence: high | evidence: captured bytecode contents and live object graph correlation
};
static_assert(offsetof(Proto, memcat) == 0x0);
static_assert(offsetof(Proto, tt) == 0x1);
static_assert(offsetof(Proto, marked) == 0x2);
static_assert(offsetof(Proto, maxstacksize) == 0x3);
static_assert(offsetof(Proto, flags) == 0x4);
static_assert(offsetof(Proto, numparams) == 0x5);
static_assert(offsetof(Proto, nups) == 0x6);
static_assert(offsetof(Proto, is_vararg) == 0x7);
static_assert(offsetof(Proto, execdata) == 0x8);
static_assert(offsetof(Proto, exectarget) == 0x10);
static_assert(offsetof(Proto, debugname) == 0x18);
static_assert(offsetof(Proto, userdata) == 0x20);
static_assert(offsetof(Proto, k) == 0x28);
static_assert(offsetof(Proto, code) == 0x30);
static_assert(offsetof(Proto, typeinfo) == 0x38);
static_assert(offsetof(Proto, debuginsn) == 0x40);
static_assert(offsetof(Proto, lineinfo) == 0x48);
static_assert(offsetof(Proto, gclist) == 0x50);
static_assert(offsetof(Proto, upvalues) == 0x58);
static_assert(offsetof(Proto, codeentry) == 0x60);
static_assert(offsetof(Proto, source) == 0x68);
static_assert(offsetof(Proto, abslineinfo) == 0x70);
static_assert(offsetof(Proto, locvars) == 0x78);
static_assert(offsetof(Proto, p) == 0x80);
static_assert(offsetof(Proto, sizeupvalues) == 0x88);
static_assert(offsetof(Proto, sizelineinfo) == 0x8c);
static_assert(offsetof(Proto, bytecodeid) == 0x90);
static_assert(offsetof(Proto, linedefined) == 0x94);
static_assert(offsetof(Proto, sizecode) == 0x98);
static_assert(offsetof(Proto, linegaplog2) == 0x9c);
static_assert(offsetof(Proto, sizelocvars) == 0xa0);
static_assert(offsetof(Proto, sizek) == 0xa4);
static_assert(offsetof(Proto, sizetypeinfo) == 0xa8);
static_assert(offsetof(Proto, sizep) == 0xac);
static_assert(offsetof(Proto, feedbackvec) == 0xb0);
static_assert(offsetof(Proto, feedbackvecsize) == 0xb8);
static_assert(offsetof(Proto, funid) == 0xbc);
static_assert(offsetof(Proto, optimized) == 0xc0);
static_assert(offsetof(Proto, deoptimized) == 0xc8);
static_assert(offsetof(Proto, cost) == 0xd0);
static_assert(sizeof(Proto) == 0xd8);

// overall confidence: high | fields: 15 high, 0 medium, 0 low
struct Closure {
    uint8_t memcat; // offset: 0x0 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
    uint8_t tt; // offset: 0x1 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
    uint8_t marked; // offset: 0x2 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
    uint8_t stacksize; // offset: 0x3 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
    uint8_t nupvalues; // offset: 0x4 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
    uint8_t preload; // offset: 0x5 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
    uint8_t isC; // offset: 0x6 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
    GCObject* gclist; // offset: 0x8 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
    LuaTable* env; // offset: 0x10 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
    union {
        struct {
            TString* debugname; // offset: 0x18 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
            lua_Continuation cont; // offset: 0x20 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
            lua_CFunction f; // offset: 0x28 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
            TValue upvals[1]; // offset: 0x30 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
        } c;
        struct {
            Proto* p; // offset: 0x18 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
            TValue uprefs[1]; // offset: 0x20 | field confidence: high | evidence: controlled C closure with sentinel callbacks and upvalues
        } l;
    };
};
static_assert(sizeof(Closure) == 0x40);


// overall confidence: high | evidence: release-matched upstream Luau definition
struct lua_Callbacks {
    void* userdata;
    void (*interrupt)(lua_State* L, int gc);
    void (*panic)(lua_State* L, int errcode);
    void (*userthread)(lua_State* LP, lua_State* L);
    int16_t (*useratom)(lua_State* L, const char* s, size_t l);
    void (*debugbreak)(lua_State* L, lua_Debug* ar);
    void (*debugstep)(lua_State* L, lua_Debug* ar);
    void (*debuginterrupt)(lua_State* L, lua_Debug* ar);
    void (*debugprotectederror)(lua_State* L);
    void (*onallocate)(lua_State* L, void* block, size_t osize, size_t nsize, uint8_t memcat, int tt, int tag);
    void (*preresume)(lua_State* L);
    void (*postresume)(lua_State* L);
    void (*onfree)(lua_State* L, void* block);
};
static_assert(sizeof(lua_Callbacks) == 0x68);

// overall confidence: high | evidence: release-matched upstream Luau definition
struct lua_ExecutionCallbacks {
    void* context;
    void (*close)(lua_State* L);
    void (*destroy)(lua_State* L, Proto* proto);
    int (*enter)(lua_State* L, Proto* proto);
    void (*disable)(lua_State* L, Proto* proto);
    size_t (*getmemorysize)(lua_State* L, Proto* proto);
    uint8_t (*gettypemapping)(lua_State* L, const char* str, size_t len);
    char* (*getcounterdata)(lua_State* L, Proto* proto, size_t* count);
    Proto* (*inlinefunction)(lua_State* L, Closure* caller, Closure* target, uint32_t pc);
};
static_assert(sizeof(lua_ExecutionCallbacks) == 0x48);

// overall confidence: high | evidence: release-matched upstream Luau definition
struct lua_UdataDirectAccessData {
    TValue indextm;
    TValue newindextm;
    TValue namecalltm;
    lua_UserdataDirectAccess index;
    lua_UserdataDirectAccess newindex;
    lua_UserdataDirectNamecall namecall;
};
static_assert(sizeof(lua_UdataDirectAccessData) == 0x48);

// overall confidence: high | evidence: release-matched upstream Luau definition
struct GCStats {
    int32_t triggerterms[32];
    uint32_t triggertermpos;
    int32_t triggerintegral;
    size_t atomicstarttotalsizebytes;
    size_t endtotalsizebytes;
    size_t heapgoalsizebytes;
    double starttimestamp;
    double atomicstarttimestamp;
    double endtimestamp;
};
static_assert(sizeof(GCStats) == 0xb8);

// overall confidence: high | evidence: release-matched upstream Luau definition
struct GCCycleMetrics {
    size_t starttotalsizebytes;
    size_t heaptriggersizebytes;
    double pausetime;
    double starttimestamp;
    double endtimestamp;
    double marktime;
    double markassisttime;
    double markmaxexplicittime;
    size_t markexplicitsteps;
    size_t markwork;
    double atomicstarttimestamp;
    size_t atomicstarttotalsizebytes;
    double atomictime;
    double atomictimeupval;
    double atomictimeweak;
    double atomictimegray;
    double atomictimeembedder;
    double atomictimeclear;
    double sweeptime;
    double sweepassisttime;
    double sweepmaxexplicittime;
    size_t sweepexplicitsteps;
    size_t sweepwork;
    size_t assistwork;
    size_t explicitwork;
    size_t propagatework;
    size_t propagateagainwork;
    size_t endtotalsizebytes;
};
static_assert(sizeof(GCCycleMetrics) == 0xe0);

// overall confidence: high | evidence: release-matched upstream Luau definition
struct GCMetrics {
    double stepexplicittimeacc;
    double stepassisttimeacc;
    uint64_t completedcycles;
    GCCycleMetrics lastcycle;
    GCCycleMetrics currcycle;
};
static_assert(sizeof(GCMetrics) == 0x1d8);

// overall confidence: medium | fields: 19 high, 31 medium, 0 low
struct global_State {
    size_t GCthreshold; // offset: 0x0 | field confidence: high | evidence: controlled Luau API mutation oracle
    size_t totalbytes; // offset: 0x8 | field confidence: high | evidence: controlled Luau API mutation oracle
    lua_Alloc frealloc; // offset: 0x10 | field confidence: high | evidence: live object identity and runtime relationship oracle
    void* ud; // offset: 0x18 | field confidence: high | evidence: live object identity and runtime relationship oracle
    stringtable strt; // offset: 0x20 | field confidence: high | evidence: live object identity and runtime relationship oracle
    uint8_t currentwhite; // offset: 0x30 | field confidence: high | evidence: live object identity and runtime relationship oracle
    uint8_t gcstate; // offset: 0x31 | field confidence: high | evidence: live object identity and runtime relationship oracle
    int gcgoal; // offset: 0x34 | field confidence: high | evidence: controlled Luau API mutation oracle
    int gcstepmul; // offset: 0x38 | field confidence: high | evidence: controlled Luau API mutation oracle
    int gcstepsize; // offset: 0x3c | field confidence: high | evidence: controlled Luau API mutation oracle
    GCObject* gray; // offset: 0x40 | field confidence: medium | evidence: runtime GC anchors and release-matched Luau adjacency invariant
    GCObject* grayagain; // offset: 0x48 | field confidence: medium | evidence: runtime GC anchors and release-matched Luau adjacency invariant
    GCObject* weak; // offset: 0x50 | field confidence: medium | evidence: runtime GC anchors and release-matched Luau adjacency invariant
    lua_Page* freepages[40]; // offset: 0x58 | field confidence: medium | evidence: runtime GC anchors and release-matched Luau adjacency invariant
    lua_Page* freegcopages[40]; // offset: 0x198 | field confidence: medium | evidence: runtime GC anchors and release-matched Luau adjacency invariant
    lua_Page* allpages; // offset: 0x2d8 | field confidence: medium | evidence: runtime GC anchors and release-matched Luau adjacency invariant
    lua_Page* allgcopages; // offset: 0x2e0 | field confidence: medium | evidence: runtime GC anchors and release-matched Luau adjacency invariant
    UpVal uvhead; // offset: 0x2e8 | field confidence: high | evidence: live object identity and runtime relationship oracle
    lua_Page* sweepgcopage; // offset: 0x310 | field confidence: medium | evidence: runtime GC anchors and release-matched Luau adjacency invariant
    lua_State* mainthread; // offset: 0x318 | field confidence: high | evidence: live object identity and runtime relationship oracle
    TString* tmname[21]; // offset: 0x320 | field confidence: high | evidence: live object identity and runtime relationship oracle
    TString* ttname[14]; // offset: 0x3c8 | field confidence: high | evidence: live object identity and runtime relationship oracle
    LuaTable* mt[14]; // offset: 0x438 | field confidence: high | evidence: live object identity and runtime relationship oracle
    TValue pseudotemp; // offset: 0x4a8 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    TValue registry; // offset: 0x4b8 | field confidence: high | evidence: live object identity and runtime relationship oracle
    int registryfree; // offset: 0x4c8 | field confidence: high | evidence: live object identity and runtime relationship oracle
    lua_jmpbuf* errorjmp; // offset: 0x4d0 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    uint64_t ptrenckey[4]; // offset: 0x4d8 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    lua_Callbacks cb; // offset: 0x4f8 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    uint64_t rngstate; // offset: 0x560 | field confidence: high | evidence: live object identity and runtime relationship oracle
    lua_ExecutionCallbacks ecb; // offset: 0x568 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    alignas(16) uint8_t ecbdata[512]; // offset: 0x5b0 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    lua_UdataDirectAccessData udatadirect[130]; // offset: 0x7b0 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    size_t memcatbytes[256]; // offset: 0x2c40 | field confidence: high | evidence: controlled Luau API mutation oracle
    void (*udatagc[128])(lua_State*, void*); // offset: 0x3440 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    lua_UserdataMark udatamark[128]; // offset: 0x3840 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    LuaTable* udatamt[128]; // offset: 0x3c40 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    TValue weakregistry; // offset: 0x4040 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    int weakregistryfree; // offset: 0x4050 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    int weakregistrytop; // offset: 0x4054 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    lua_EmbedderGc embeddergc; // offset: 0x4058 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    TString* lightuserdataname[128]; // offset: 0x4060 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    LuaTable* udatadirectfields[130]; // offset: 0x4460 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    Closure* builtinPcall; // offset: 0x4870 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    Closure* builtinXpcall; // offset: 0x4878 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    uint64_t ptrenckeynew[8]; // offset: 0x4880 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    bool ptrencactive; // offset: 0x48c0 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    GCStats gcstats; // offset: 0x48c8 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    uint32_t lastprotoid; // offset: 0x4980 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
    GCMetrics gcmetrics; // offset: 0x4988 | field confidence: medium | evidence: runtime anchors, release-matched Luau types, and checked field spans
};
static_assert(offsetof(global_State, GCthreshold) == 0x0);
static_assert(offsetof(global_State, totalbytes) == 0x8);
static_assert(offsetof(global_State, frealloc) == 0x10);
static_assert(offsetof(global_State, ud) == 0x18);
static_assert(offsetof(global_State, strt) == 0x20);
static_assert(offsetof(global_State, currentwhite) == 0x30);
static_assert(offsetof(global_State, gcstate) == 0x31);
static_assert(offsetof(global_State, gcgoal) == 0x34);
static_assert(offsetof(global_State, gcstepmul) == 0x38);
static_assert(offsetof(global_State, gcstepsize) == 0x3c);
static_assert(offsetof(global_State, gray) == 0x40);
static_assert(offsetof(global_State, grayagain) == 0x48);
static_assert(offsetof(global_State, weak) == 0x50);
static_assert(offsetof(global_State, freepages) == 0x58);
static_assert(offsetof(global_State, freegcopages) == 0x198);
static_assert(offsetof(global_State, allpages) == 0x2d8);
static_assert(offsetof(global_State, allgcopages) == 0x2e0);
static_assert(offsetof(global_State, uvhead) == 0x2e8);
static_assert(offsetof(global_State, sweepgcopage) == 0x310);
static_assert(offsetof(global_State, mainthread) == 0x318);
static_assert(offsetof(global_State, tmname) == 0x320);
static_assert(offsetof(global_State, ttname) == 0x3c8);
static_assert(offsetof(global_State, mt) == 0x438);
static_assert(offsetof(global_State, pseudotemp) == 0x4a8);
static_assert(offsetof(global_State, registry) == 0x4b8);
static_assert(offsetof(global_State, registryfree) == 0x4c8);
static_assert(offsetof(global_State, errorjmp) == 0x4d0);
static_assert(offsetof(global_State, ptrenckey) == 0x4d8);
static_assert(offsetof(global_State, cb) == 0x4f8);
static_assert(offsetof(global_State, rngstate) == 0x560);
static_assert(offsetof(global_State, ecb) == 0x568);
static_assert(offsetof(global_State, ecbdata) == 0x5b0);
static_assert(offsetof(global_State, udatadirect) == 0x7b0);
static_assert(offsetof(global_State, memcatbytes) == 0x2c40);
static_assert(offsetof(global_State, udatagc) == 0x3440);
static_assert(offsetof(global_State, udatamark) == 0x3840);
static_assert(offsetof(global_State, udatamt) == 0x3c40);
static_assert(offsetof(global_State, weakregistry) == 0x4040);
static_assert(offsetof(global_State, weakregistryfree) == 0x4050);
static_assert(offsetof(global_State, weakregistrytop) == 0x4054);
static_assert(offsetof(global_State, embeddergc) == 0x4058);
static_assert(offsetof(global_State, lightuserdataname) == 0x4060);
static_assert(offsetof(global_State, udatadirectfields) == 0x4460);
static_assert(offsetof(global_State, builtinPcall) == 0x4870);
static_assert(offsetof(global_State, builtinXpcall) == 0x4878);
static_assert(offsetof(global_State, ptrenckeynew) == 0x4880);
static_assert(offsetof(global_State, ptrencactive) == 0x48c0);
static_assert(offsetof(global_State, gcstats) == 0x48c8);
static_assert(offsetof(global_State, lastprotoid) == 0x4980);
static_assert(offsetof(global_State, gcmetrics) == 0x4988);
static_assert(sizeof(global_State) == 0x4b60);

// overall confidence: high | fields: 1 high, 0 medium, 0 low
struct RobloxExtraSpace {
    std::byte _pad0[0x40];
    uint64_t capabilities; // offset: 0x40 | field confidence: high | evidence: Roblox effective-capabilities accessor mutation oracle
};
static_assert(offsetof(RobloxExtraSpace, capabilities) == 0x40);

// overall confidence: medium | fields: 19 high, 6 medium, 0 low
struct lua_State {
    uint8_t memcat; // offset: 0x0 | field confidence: high | evidence: luaE_newthread propagation
    uint8_t tt; // offset: 0x1 | field confidence: medium | evidence: constrained elimination across parent and child states
    uint8_t marked; // offset: 0x2 | field confidence: medium | evidence: constrained elimination across parent and child states
    uint8_t status; // offset: 0x3 | field confidence: high | evidence: lua_status oracle
    uint8_t activememcat; // offset: 0x4 | field confidence: high | evidence: luaE_newthread propagation
    bool singlestep; // offset: 0x5 | field confidence: medium | evidence: constrained elimination across parent and child states
    bool isactive; // offset: 0x6 | field confidence: high | evidence: parent and child execution delta
    unsigned short nCcalls; // offset: 0x8 | field confidence: high | evidence: lua_isyieldable oracle
    unsigned short baseCcalls; // offset: 0xa | field confidence: high | evidence: lua_isyieldable oracle
    int cachedslot; // offset: 0xc | field confidence: medium | evidence: constrained elimination across parent and child states
    int stacksize; // offset: 0x10 | field confidence: high | evidence: multi-state stack bounds and capacity
    int size_ci; // offset: 0x14 | field confidence: high | evidence: multi-state CallInfo array invariants
    CallInfo* end_ci; // offset: 0x18 | field confidence: high | evidence: multi-state CallInfo array invariants
    CallInfo* base_ci; // offset: 0x20 | field confidence: high | evidence: multi-state CallInfo array invariants
    GCObject* gclist; // offset: 0x28 | field confidence: medium | evidence: constrained elimination across parent and child states
    TString* namecall; // offset: 0x30 | field confidence: high | evidence: lua_namecallatom oracle
    LuaTable* gt; // offset: 0x38 | field confidence: high | evidence: GC tag and backlink relationship
    UpVal* openupval; // offset: 0x40 | field confidence: high | evidence: luaF_findupval and close oracle
    void* userdata; // offset: 0x48 | field confidence: medium | evidence: constrained elimination across parent and child states
    CallInfo* ci; // offset: 0x50 | field confidence: high | evidence: multi-state CallInfo array invariants
    StkId base; // offset: 0x58 | field confidence: high | evidence: lua_gettop and controlled push transitions
    StkId stack; // offset: 0x60 | field confidence: high | evidence: multi-state stack bounds and capacity
    StkId stack_last; // offset: 0x68 | field confidence: high | evidence: multi-state stack bounds and capacity
    global_State* global; // offset: 0x70 | field confidence: high | evidence: GC tag and backlink relationship
    StkId top; // offset: 0x78 | field confidence: high | evidence: lua_gettop and controlled push transitions
};
static_assert(offsetof(lua_State, memcat) == 0x0);
static_assert(offsetof(lua_State, tt) == 0x1);
static_assert(offsetof(lua_State, marked) == 0x2);
static_assert(offsetof(lua_State, status) == 0x3);
static_assert(offsetof(lua_State, activememcat) == 0x4);
static_assert(offsetof(lua_State, singlestep) == 0x5);
static_assert(offsetof(lua_State, isactive) == 0x6);
static_assert(offsetof(lua_State, nCcalls) == 0x8);
static_assert(offsetof(lua_State, baseCcalls) == 0xa);
static_assert(offsetof(lua_State, cachedslot) == 0xc);
static_assert(offsetof(lua_State, stacksize) == 0x10);
static_assert(offsetof(lua_State, size_ci) == 0x14);
static_assert(offsetof(lua_State, end_ci) == 0x18);
static_assert(offsetof(lua_State, base_ci) == 0x20);
static_assert(offsetof(lua_State, gclist) == 0x28);
static_assert(offsetof(lua_State, namecall) == 0x30);
static_assert(offsetof(lua_State, gt) == 0x38);
static_assert(offsetof(lua_State, openupval) == 0x40);
static_assert(offsetof(lua_State, userdata) == 0x48);
static_assert(offsetof(lua_State, ci) == 0x50);
static_assert(offsetof(lua_State, base) == 0x58);
static_assert(offsetof(lua_State, stack) == 0x60);
static_assert(offsetof(lua_State, stack_last) == 0x68);
static_assert(offsetof(lua_State, global) == 0x70);
static_assert(offsetof(lua_State, top) == 0x78);
static_assert(sizeof(lua_State) == 0x80);

// overall confidence: high | fields: 5 high, 0 medium, 0 low
struct RobloxInstance {
    void** vtable; // offset: 0x0 | field confidence: high | evidence: executable virtual-function table
    std::byte _pad0[0x10];
    void* class_descriptor; // offset: 0x18 | field confidence: high | evidence: cross-object ScriptContext and Ugc name correlation
    std::byte _pad1[0x48];
    RobloxInstance* parent; // offset: 0x68 | field confidence: high | evidence: ScriptContext to Ugc parent relationship
    RobloxString* name; // offset: 0x70 | field confidence: high | evidence: cross-object ScriptContext and Ugc name correlation
    RobloxInstance (*children)[]; // offset: 0x78 | field confidence: high | evidence: parent children vector contains ScriptContext
};
static_assert(offsetof(RobloxInstance, vtable) == 0x0);
static_assert(offsetof(RobloxInstance, class_descriptor) == 0x18);
static_assert(offsetof(RobloxInstance, parent) == 0x68);
static_assert(offsetof(RobloxInstance, name) == 0x70);
static_assert(offsetof(RobloxInstance, children) == 0x78);

} // namespace structures
