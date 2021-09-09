local Modules = {};
local _initialed = false

function _G.moduleInitial()
  if _initialed then
    return
  end
  _initialed = true;
  local sql = [[
create table if not exists lua_migration
(
    id     int          not null,
    module varchar(100) not null,
    name   varchar(255) not null,
    constraint lua_migration_pk
        primary key (module, id)
);
]]
  logInfo('-', SQL.querySQL(sql));
end

---@param forceReload boolean
---@param moduleName string
---@param path string
function _G.loadModule(moduleName, path, forceReload)
  local oPath = path;
  path = 'lua/Modules/' .. path;
  log('ModuleSystem', 'INFO', 'load module ', moduleName, path, forceReload)
  if Modules[moduleName] and not forceReload then
    return Modules[moduleName];
  end
  if Modules[moduleName] then
    Modules[moduleName]:unload();
  end
  Modules[moduleName] = nil;
  local ctx = {}
  local result, module = pcall(function()
    return loadfile(path, 'bt', setmetatable(ctx, { __index = _G }))()
  end)
  if not result then
    log('ModuleSystem', 'ERROR', 'load module failed.', moduleName, path, forceReload, '\n', module)
    return nil;
  end
  module = module:new();
  --logInfo('ModuleSystem', 'new object', moduleName, module)
  Modules[moduleName] = module;
  module.___path = oPath;
  module.___ctx = ctx;
  module:load();
  return module;
end

function _G.unloadModule(moduleName)
  if Modules[moduleName] then
    Modules[moduleName]:unload();
    Modules[moduleName] = nil;
  end
end

function _G.reloadModule(moduleName)
  logInfo('ModuleSystem', moduleName, Modules[moduleName])
  local module = Modules[moduleName];
  if module then
    module:unload();
    local path = module.___path;
    return loadModule(moduleName, path, true);
  end
  return nil;
end

function _G.getModule(moduleName)
  return Modules[moduleName];
end

local chained = {
  TalkEvent = function(list, ...)
    local res = 1;
    for i, v in pairs(list) do
      res = v(...)
      if res ~= 1 then
        return res;
      end
    end
    return res
  end,
  BattleDamageEvent = function(list, CharIndex, DefCharIndex, OriDamage, Damage, BattleIndex, Com1, Com2, Com3, DefCom1, DefCom2, DefCom3, Flg)
    local dmg = Damage;
    for i, v in pairs(list) do
      dmg = v(CharIndex, DefCharIndex, OriDamage, dmg, BattleIndex, Com1, Com2, Com3, DefCom1, DefCom2, DefCom3, Flg)
      if type(dmg) ~= 'number' or dmg <= 0 then
        dmg = 1
      end
    end
    return dmg
  end
}

local function makeEventHandle(name)
  local list = {}
  local fn = function(list, ...)
    local res;
    for i, v in pairs(list) do
      res = v(...)
    end
    --logDebug('ModuleSystem', 'callback', name, res, ...)
    return res
  end
  return Func.bind(chained[name] or fn, list), list
end

local eventCallbacks = {}
local ix = 0;
function _G.regGlobalEvent(eventName, fn, moduleName, extraSign)
  extraSign = extraSign or ''
  logInfo('ModuleSystem', 'regGlobalEvent', eventName, moduleName, ix + 1, eventCallbacks[eventName .. extraSign])
  if eventCallbacks[eventName .. extraSign] == nil then
    --logInfo('ModuleSystem', 'Reg2' .. eventName, NL['Reg' .. eventName])
    local fn1, list = makeEventHandle(eventName);
    eventCallbacks[eventName .. extraSign] = list;
    _G[(eventName .. extraSign)] = fn1;
    if NL['Reg' .. eventName] then
      logInfo('ModuleSystem', 'NL.Reg' .. eventName, extraSign)
      if extraSign == '' then
        NL['Reg' .. eventName](nil, eventName .. extraSign);
      else
        NL['Reg' .. eventName](nil, eventName .. extraSign, extraSign);
      end
    end
  end
  ix = ix + 1;
  eventCallbacks[eventName .. extraSign][ix] = function(...)
    --logDebug('ModuleSystem', 'callback', eventName .. extraSign, fn, ...)
    local success, result = pcall(fn, ...)
    if not success then
      log(moduleName, 'ERROR', eventName .. extraSign .. ' event callback error: ', result)
      return nil;
    end
    --logDebug('ModuleSystem', 'callback', eventName .. extraSign, fn, result, ...)
    return result;
  end
  return ix;
end
function _G.unRegGlobalEvent(eventName, fnIndex, moduleName, extraSign)
  extraSign = extraSign or ''
  log('ModuleSystem', 'INFO', 'unRegGlobalEvent', eventName .. extraSign, moduleName, fnIndex)
  if not eventCallbacks[eventName .. extraSign] then
    return true;
  end
  eventCallbacks[eventName .. extraSign][fnIndex] = nil
  if table.isEmpty(eventCallbacks[eventName .. extraSign]) then
    if not NL['Reg' .. eventName] then
      eventCallbacks[eventName .. extraSign] = nil;
      _G[eventName .. extraSign] = nil;
    end
  end
  return true;
end
