local fn = function(charPtr, mapType, floor, x, y)
  printAsHex(charPtr, mapType, floor, x, y)
  ffi.setMemoryInt32(mapType, Char.GetDataByPtr(charPtr, CONST.CHAR_��ͼ����))
  ffi.setMemoryInt32(floor, Char.GetDataByPtr(charPtr, CONST.CHAR_��ͼ))
  ffi.setMemoryInt32(x, Char.GetDataByPtr(charPtr, CONST.CHAR_X))
  ffi.setMemoryInt32(y, Char.GetDataByPtr(charPtr, CONST.CHAR_Y))
  return 1
end

ffi.hook.inlineHook('int (__cdecl *)(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t)', fn, 0x0043A43E, 6, {
  0x50, --push eax,
  0x8B, 0x45, 0x18, --mov eax, [ebp+0x18]
  0x50, --push eax,
  0x8B, 0x45, 0x14, --mov eax, [ebp+0x18]
  0x50, --push eax,
  0x8B, 0x45, 0x10, --mov eax, [ebp+0x18]
  0x50, --push eax,
  0x8B, 0x45, 0xC, --mov eax, [ebp+0x18]
  0x50, --push eax,
  0x53, --push ebx,
}, {
  0x58,
  0x58,
  0x58,
  0x58,
  0x58,
  0x58,
});
print('[DEBUG] NL_GetLoginPoint_Patch done')
