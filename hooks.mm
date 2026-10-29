// hooks.mm
#import "hooks.hpp"
#import "exploit.hpp"

// Callback executado a cada frame
static int ScriptsHandler(lua_State* L) {
    if (!ExecutionRequests.empty()) {
        std::string Script = ExecutionRequests.front();
        ExecutionRequests.erase(ExecutionRequests.begin());
        
        // Compila e executa
        ExecuteScript(ExploitThread, Script);
    }
    return 0;
}

// Conecta o handler ao RenderStepped
void SetupExecution(lua_State* L) {
    lua_getglobal(L, "game");
    lua_getfield(L, -1, "GetService");
    lua_pushvalue(L, -2);
    lua_pushstring(L, "RunService");
    lua_pcall(L, 2, 1, 0);
    
    lua_getfield(L, -1, "RenderStepped");
    lua_pushcclosure(L, ScriptsHandler, 0, nullptr);
    lua_pcall(L, 1, 1, 0);
    
    lua_pop(L, 2);
}

// Chamado pela UI quando o botão Execute é clicado
void RequestExecution(const std::string& Script) {
    ExecutionRequests.push_back(Script);
}
