#pragma once
#include <string>
#include <mutex>
#include "structs.h"

class SporkExecutor {
public:
    static void Initialize();
    static void CaptureLuaState(structures::lua_State* L);
    static bool QueueScript(const std::string& source);
    static void ProcessQueue();
};
