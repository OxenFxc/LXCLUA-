--- kv数据库
---@class LuaDB
---@field private F table 格式串
---@field private fw file db文件
---@field private fm file map文件
---@field private node_id integer 节点id
---@field byte_order string 字节序
---@field block_size integer 簇大小
---@field addr_size integer 地址长度
---@field ver integer 数据库版本
---@field BIT_16 integer 地址16位
---@field BIT_24 integer 地址24位
---@field BIT_32 integer 地址32位
---@field BIT_48 integer 地址48位
---@field BIT_64 integer 地址64位
---@field BYTE_LE string 小端
---@field BYTE_BE string 大端
---@field BYTE_AUTO string 跟随系统
---@field TYPE_DB LUADB_DB 子数据库
---@field TYPE_ID LUADB_ID 成员指针
---@field TYPE_ADDR LUADB_ADDR 成员地址
local db = {
  ver = 32,
  BIT_16 = 2,
  BIT_24 = 3,
  BIT_32 = 4,
  BIT_48 = 6,
  BIT_64 = 8,
  BYTE_LE = '<',
  BYTE_BE = '>',
  BYTE_AUTO = '=',
  TYPE_ID = {},
  TYPE_ADDR = {},
  TYPE_DB = {}
}

---@class LUADB_ADDR
---@field pointer integer 指针地址
---@field addr integer 成员地址
---@field key_size integer key长度
---@field key string key
---@field name string 成员名称

---@class LUADB_ID: LUADB_ADDR

---@class LUADB_DB
---@field __call function

-- global转local
local pack, unpack = string.pack, string.unpack
local type, pairs, tostring, setmetatable, getmetatable, error, assert, load, next, tonumber =
type, pairs, tostring, setmetatable, getmetatable, error, assert, load, next, tonumber
local math_type, string_dump, table_concat, string_byte, table_unpack, table_insert =
math.type, string.dump, table.concat, string.byte, table.unpack, table.insert

-- 格式串模板
local _F = { 'c5BAA', 'c5B', 'i8', 's', 'n', 'A', 'AA', 'B', 'T', 'sB' }
local _C = { -- 配置模板
  node_id = 6,
  block_size = 4096,
  addr_size = db.BIT_32,
  byte_order = db.BYTE_AUTO
}

---序列化类型
local NIL = 0
local STRING = 1
local INTEGER = 2
local DOUBLE = 3
local BOOLEAN = 4
local FUNCTION = 5
local TABLE = 6
local NUMBER = 7

--- 序列化table
---@private
---@param t table
---@return string
local function serialize(t)
  local s = {}
  for k, v in next, t do
    local tp = type(k)
    if tp == 'string' then
      table_insert(s, (pack('Bs2', STRING, k)))
     elseif tp == 'number' then
      table_insert(s, (pack('Bn', NUMBER, k)))
    end
    tp = type(v)
    if tp == 'string' then
      table_insert(s, (pack('Bs4', STRING, v)))
     elseif tp == 'number' then
      if math_type(v) == 'integer' then
        table_insert(s, (pack('Bi8', INTEGER, v)))
       else
        table_insert(s, (pack('Bn', DOUBLE, v)))
      end
     elseif tp == 'boolean' then
      table_insert(s, (pack('BB', BOOLEAN, v and 1 or 0)))
     elseif tp == 'function' then
      table_insert(s, (pack('Bs4', FUNCTION, string_dump(v, true))))
     elseif tp == 'table' then
      table_insert(s, (pack('B', TABLE)))
      table_insert(s, serialize(v))
      table_insert(s, (pack('B', TABLE)))
     else
      table_insert(s, (pack('B', NIL)))
    end
  end
  return table_concat(s)
end

--- 反序列化table
---@private
---@param b string 二进制串
---@return table
local function deserialize(b)
  local pos = 1
  local sf = {}
  local stack = {}
  while true do
    local pop, pass = stack[#stack] or sf
    local tp, k = b:sub(pos, pos)
    pos = pos + 1
    if tp == '' then break end
    tp = unpack('B', tp)
    if tp == NUMBER then
      k = unpack('n', b, pos)
      pos = pos + 8
     elseif tp == STRING then
      k = unpack('s2', b, pos)
      pos = pos + #k + 2
     else
      stack[#stack] = nil
      pass = true
    end
    if not pass then
      local tp, v = b:sub(pos, pos)
      pos = pos + 1
      tp = unpack('B', tp)
      if tp == STRING then
        v = unpack('s4', b, pos)
        pos = pos + #v + 4
       elseif tp == INTEGER then
        v = unpack('i8', b, pos)
        pos = pos + 8
       elseif tp == DOUBLE then
        v = unpack('n', b, pos)
        pos = pos + 8
       elseif tp == BOOLEAN then
        v = unpack('B', b, pos) == 1
        pos = pos + 1
       elseif tp == FUNCTION then
        v = unpack('s4', b, pos)
        pos = pos + #v + 4
        v = load(v)
       elseif tp == TABLE then
        v = {}
        stack[#stack + 1] = v
      end
      pop[k] = v
    end
  end
  return sf
end

--- hash函数
---@private
---@param s any 数值
---@return integer
local function hash(s)
  if math_type(s) == 'integer' then
    if s > 0 then
      return s
    end
  end
  s = tostring(s)
  local l = #s
  local h = l
  local step = (l >> 5) + 1
  for i = l, step, -step do
    h = h ~ ((h << 5) + string_byte(s, i) + (h >> 2))
  end
  return h
end

--- 打开数据库
---@param config table|string 路径或配置表
---@return LuaDB
function db.open(config)
  if type(config) == 'string' then
    config = {
      path = config
    }
  end
  for k, v in pairs(_C) do
    local c = config[k]
    if c == nil then
      config[k] = v
    end
  end
  local self = config
  setmetatable(self, db)
  local F = {}
  for i = 1, #_F do
    local v = _F[i]
    local _v = v:gsub('A', 'I' .. self.addr_size)
    F[v] = self.byte_order .. _v
  end
  self.F = F

  -- 统一映射文件命名规则：取文件名（不含扩展名）加上.map后缀
  local map_path = self.path:match("(.-)%.[^/\\]*$")
  if not map_path or map_path == "" then
    map_path = self.path
  end
  self.map_path = map_path .. ".map"

  local f = io.open(self.path)
  if f then
    f:close()
    self:init()
   else
    self:reset()
  end
  return self
end

--- 加载数据库
---@private
---@return LuaDB
function db:init()
  -- 打开文件对象并设置缓冲模式
  self.fw = io.open(self.path, 'r+b')
  if not self.fw then
    error('LuaDB::无法打开数据库文件: ' .. self.path)
  end
  self.fw:setvbuf('no')
  
  -- 使用统一的映射文件路径
  self.fm = io.open(self.map_path, 'r+b')
  if not self.fm then
    -- 如果 .map 文件不存在，创建它
    self.fm = io.open(self.map_path, 'w+b')
    if not self.fm then
      error('LuaDB::无法创建映射文件: ' .. self.map_path)
    end
  end
  self.fm:setvbuf('no')
  
  -- 校验文件标识，并赋值版本号
  local s = self.fw:read(6)
  assert(s, 'LuaDB::数据格式错误！')
  assert(#s >= 6, 'LuaDB::数据格式错误！')
  local tag, ver = unpack(self.F.c5B, s)
  self.ver = ver
  assert(tag == 'LuaDB', 'LuaDB::数据格式错误！')
  return self
end

---重置数据库
---@return LuaDB
function db:reset()
  -- 创建数据库文件，写入信息
  io.open(self.path, 'wb'):write((pack(self.F.c5BAA, 'LuaDB', db.ver, 0, 0))):close()
  
  -- 使用统一的映射文件路径
  local map_file = io.open(self.map_path, 'wb')
  if map_file then
    map_file:close()
  end
  
  self:init() -- 加载数据库
  return self
end

--- 打包数据
---@private
---@param v any 数据
---@return integer,integer,any
function db:pack(v)
  local F = self.F
  local tp, len, mode = type(v), 0
  if v == nil then
    tp = 0
    v = ''
    len = 0
   elseif tp == 'string' then
    tp = 1
    v = pack(F.s, v)
    len = #v
   elseif math_type(v) == 'integer' then
    tp = 2
    len = 8
    v = pack(F.i8, v)
   elseif tp == 'number' then
    tp = 3
    len = 8
    v = pack(F.n, v)
   elseif tp == 'boolean' then
    tp = 4
    len = 1
    v = v and '\1' or '\0'
   elseif tp == 'function' then
    tp = 5
    v = pack(F.s, string_dump(v, true))
    len = #v
   elseif getmetatable(v) == db.TYPE_DB then
    tp = 6
    v = pack(F.AA, 0, 0)
    len = self.addr_size * 2
   elseif tp == 'table' then
    tp = 7
    v = pack(F.s, serialize(v))
    len = #v
   else
    error('LuaDB::不支持的类型::' .. tp)
  end
  return tp, len, v
end

--- 解包数据
---@private
---@param addr integer 解包地址
---@return any
function db:unpack(addr)
  local F = self.F
  local fw = self.fw
  fw:seek('set', addr)
  local tp = unpack(F.B, fw:read(1))
  if tp == 1 then
    local n = unpack(F.T, fw:read(8))
    return fw:read(n)
   elseif tp == 2 then
    return (unpack(F.i8, fw:read(8)))
   elseif tp == 3 then
    return (unpack(F.n, fw:read(8)))
   elseif tp == 4 then
    return fw:read(1) == '\1'
   elseif tp == 5 then
    local n = unpack(F.T, fw:read(8))
    return load(fw:read(n))
   elseif tp == 6 then
    local v0 = setmetatable({}, db)
    for k, v in pairs(self) do
      v0[k] = v
    end
    v0.node_id = addr + 1
    return v0
   elseif tp == 7 then
    local n = unpack(F.T, fw:read(8))
    return deserialize(fw:read(n))
  end
end

--- 成员指针
---@param key any|LUADB_ADDR key或成员地址
---@return LUADB_ID
function db:id(key)
  if getmetatable(key) == db.TYPE_ADDR then
    local o = { pointer = key.pointer, key = key.key, name = key.name }
    return setmetatable(o, db.TYPE_ID)
  end
  local po = self:get_pointer(key)
  local name = key
  if self.node_id > 6 then
    name = name:sub(self.addr_size + 1)
  end
  local o = { pointer = po, key = key, name = name }
  return setmetatable(o, db.TYPE_ID)
end

--- 加载成员指针
---@param key any 成员key
---@param po integer 指针地址
---@return LUADB_ID
function db:load_id(key, po)
  local name = key
  if self.node_id > 6 then
    name = name:sub(self.addr_size + 1)
  end
  local o = { pointer = po, key = key, name = name }
  return setmetatable(o, db.TYPE_ID)
end

--- 成员地址
---@param id any|LUADB_ID 成员key或成员指针
---@return LUADB_ADDR
function db:addr(id)
  if getmetatable(id) ~= db.TYPE_ID then
    local po, addr, size = self:get_pointer(id)
    local name = id
    if self.node_id > 6 then
      name = name:sub(self.addr_size + 1)
    end
    local o = { pointer = po, addr = addr, key_size = size, key = id, name = name }
    return setmetatable(o, db.TYPE_ADDR)
  end
  local addr, size = self:get_addr(id.pointer, id.key)
  local o = { pointer = id.pointer, addr = addr, key_size = size, key = id.key, name = id.name }
  return setmetatable(o, db.TYPE_ADDR)
end

---获取指针地址
---@private
---@param key any 成员key
---@return integer,integer,integer,any
function db:get_pointer(key)
  local level, block_size = 0, self.block_size
  local addr_size = self.addr_size
  local hash_code = (hash(key) % block_size) + 1
  key = tostring(key)
  block_size = block_size * addr_size
  hash_code = hash_code * addr_size

  while true do
    local pointer = (level * block_size) + hash_code
    local a, b = self:get_addr(pointer, key)
    if a then
      return pointer, a, b, key
    end
    level = level + 1
  end
end

--- 获取地址
---@private
---@param pointer integer 指针地址
---@param key any 成员key
---@return integer,integer
function db:get_addr(pointer, key)
  local addr_size, F = self.addr_size, self.F
  local fw, fm = self.fw, self.fm
  fm:seek('set', pointer)
  local addr = fm:read(addr_size)
  if addr then
    addr = unpack(F.A, addr)
   else
    addr = 0
  end
  if addr == 0 then
    return 0
   else
    fw:seek('set', addr)
    local n = fw:read(8)
    n = unpack(F.T, n)
    local s = fw:read(n)
    if s == key then
      return addr, n
    end
  end
end

--- 指向新的地址
---@private
---@param po integer 指针地址
---@return integer
function db:new_addr(po)
  local F = self.F
  local fw, fm = self.fw, self.fm
  fm:seek('set', po)
  local n = fw:seek('end')
  fm:write(pack(F.A, n))
  return n
end

--- 检查key类型并调用
---@private
---@param k any|LUADB_ID|LUADB_ADDR 成员身份
---@return integer,integer,integer,string,LUADB_ADDR
function db:check_key(k)
  local p = getmetatable(k)
  if p == db.TYPE_ID then
    local pointer, key = k.pointer, k.key
    local addr, size = self:get_addr(pointer, key)
    return pointer, addr, size, key
   elseif p == db.TYPE_ADDR then
    return k.pointer, k.addr, k.key_size, k.key, k
  end
  if self.node_id > 6 then
    k = pack(self.F.A, self.node_id) .. tostring(k)
  end
  return self:get_pointer(k)
end

--- 写入数据
---@param k any|LUADB_ID|LUADB_ADDR 成员身份
---@param v any|LUADB_DB 值
---@return LuaDB
function db:set(k, v)
  local F = self.F
  local _v = v
  local fw, fm = self.fw, self.fm
  local tp, len, v = self:pack(v)
  local po, addr, size, k, ck = self:check_key(k)
  k = tostring(k)
  if addr == 0 then
    size = #k
    addr = self:new_addr(po)
   else
    fw:seek('set', addr + 8 + size)
    local tp, n = unpack(F.B, fw:read(1))
    if tp == 1 or tp == 5 or tp == 7 then
      n = 8 + unpack(F.T, fw:read(8))
     elseif tp == 6 then
      n = self.addr_size * 2
     elseif tp == 2 or tp == 3 then
      n = 8
     elseif tp == 4 then
      n = 1
     else
      n = 0
    end
    if n < len then
      addr = self:new_addr(po)
      if ck then
        ck.addr = addr
      end
    end
  end
  fw:seek('set', addr)
  fw:write(pack(F.sB, k, tp))
  fw:write(v)
  if tp == 6 then
    local v0
    for k, v in pairs(_v) do
      if k ~= '__call' then
        if not v0 then
          v0 = setmetatable({}, db)
          for k, v in pairs(self) do
            v0[k] = v
          end
          v0.node_id = addr + 8 + size + 1
        end
        v0:set(k, v)
      end
    end
  end
  return self
end

--- 读取数据
---@param k any|LUADB_ID|LUADB_ADDR 成员key
---@return any
function db:get(k)
  local po, addr, size = self:check_key(k)
  if addr == 0 then
    return
  end
  local v = self:unpack(addr + 8 + size)
  return v
end

--- 删除数据 (将成员赋值为空)
---@param k any|LUADB_ID|LUADB_ADDR 成员key
---@return LuaDB
function db:del(k)
  return self:set(k)
end

--- 成员是否存在
---@param k any|LUADB_ID|LUADB_ADDR 成员key
---@return boolean
function db:has(k)
  local po, addr, size = self:check_key(k)
  return addr > 0
end

--- 关闭数据库
---@return LuaDB
function db:close()
  self.fw:close()
  self.fm:close()
  return self
end

--- 子数据库的元方法
---@private
function db.TYPE_DB:__call(t)
  return setmetatable(t, self)
end

---@private
function db:__tostring()
  return string.format('LuaDB: %s', self.path)
end

---@private
db.__index = db
setmetatable(db.TYPE_DB, db.TYPE_DB)
return db
