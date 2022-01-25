ffi.patch(0x00478802, { 0x8B, 0x45, 0xE4, 0x01, 0x45, 0x14, 0x8B, 0x1D, 0xE8, 0x3C, 0x61, 0x09 })
ffi.patch(0x00478724 + 2, { 0xD8 + 6 })
ffi.patch(0x004788E2, { 0x89, 0xD0, 0x90 })
ffi.patch(0x00576E26 + 1, { 0x15, 0xD5 })

local GetSuitsetTechOpt = ffi.cast('int (__cdecl*)(uint32_t charAddr, int techId, const char *type, int val)', 0x00478710);
ffi.hook.inlineHook('int (__cdecl *)(const char*, uint32_t, uint32_t)', function(techData, charPtr, valPtr)
  local s = ffi.string(techData);
  local v = 0;
  v = string.match(s, "AR:(%d+)")
  --print(s, v);
  if v == nil then
    v = 0
  else
    v = tonumber(v) or 0;
  end
  local charIndex = ffi.readMemoryInt32(charPtr + 4);
  local techId = Char.GetData(charIndex, CONST.CHAR_BattleCom3) or -1;
  local techIndex = Tech.GetTechIndex(techId);
  --print(charIndex, charPtr, techId, v);
  --printAsHex(valPtr, tostring(ffi.readMemoryInt32(valPtr)));
  v = GetSuitsetTechOpt(charPtr, techIndex, ffi.cast('void*', 0x0061B9CA), v);
  --print(charIndex, charPtr, techId, v)
  ffi.setMemoryInt32(valPtr, v);
  return 0;
end, 0x00498D52, 0x00498D78 - 0x00498D52, {
  0x60, 0x9C,
  0x8D, 0x45, 0xE4, --lea     eax, [ebp+var_1C]
  0x50, --push eax
  0x57, --push edi
  0x52, --push edx  
}, {
  0x58, --pop eax
  0x58, --pop eax
  0x58, --pop eax
  0x9D, 0x61,
}, { ignoreOriginCode = true })
