### manifest.json配置文档

---

#### ** 软件名称 **
通过修改字段 `label` 自定义软件名称<br>
```lua
-- 例如这段代码用于指定软件名称为 LXCLUA
"label": "LXCLUA",
```

---

#### ** 软件包名 **
通过修改字段 `package` 自定义软件包名<br>
```lua
-- 例如这段代码用于指定软件包名为 com.difierline.lua.luaappx
"package": "com.difierline.lua.luaappx",
```
#### 包名是什么？<br>
Android 应用的软件包名称是应用在设备上的唯一标识<br><br>

#### 包名的命名规则<br>
可以包含大写字母(A到Z)、小写字母(a到z)、数字和下划线，可以用点(英文句号)分隔，隔开的每一段都必须以字母开头。<br><br>

#### 避免包名冲突<br>
因为包名是唯一标识，为了避免与其他应用的包名重复，产生冲突，您可以这样命名：<br>
将您的域名反转过来作为前缀，比如如果您的域名是 `example.com`，那么包名可以用 `com.example` 开头，这样可以有效的避免重复<br><br>
在后面增加描述产品名称的字符，比如果果您的应用是视频应用，可以命名为 `com.example.video`
如果您没有域名，您也可以使用自己的邮箱作为前缀，比如 `com.163.luaapp`<br><br>

---

#### ** 版本名称 **
字段 `versionName` 的作用：<br>
```lua
-- 例如这段代码用于指定软件版本名称为 1.0.0
"versionName": "1.0.0",

-- 常见软件版本号的形式是 major.minor.maintenance.build

-- major是主版本号，一般在软件有重大升级时增长
-- minor是次版本号，一般在软件有新功能时增长
-- maintenance是维护版本，一般在软件有主要的问题修复后增长
-- build构建版本（测试版本一般会用到）

-- 一般情况下版本名称命名为3段，即前3段
```

---

#### ** 版本代号 **
字段 `versionCode` 的作用：<br>
```lua
-- 例如这段代码用于指定软件版本为 1099
"versionCode": "1099",
-- 版本代号是给开发者看的，用于比较开发顺序和应用版本高低
-- 它只能是数字，通过比较大小可以知道应用是否需要更新等等
```

---

#### ** 最小SDK **
字段 `minSdkVersion` 的作用：<br>
```lua
-- minSdkVersion 是应用可以运行的Android SDK的最低版本。 用来判断用户设备是否可以安装某个应用的标志之一
"minSdkVersion": 21,

```

---

#### ** 目标SDK **
字段 ` targetSdkVersion` 的作用：<br>
```lua
-- targetSdkVersion 是用于指定应用的目标Android版本（API等级），设置targetSdkVersion 的值即表示App 适配的Android版本（API等级），设置低版本的targetSdkVersion 会使APP 兼容模式运行，也就可能无法用到新系统的特性，甚至在兼容模式下运行可能存在安全问题
"targetSdkVersion": 29,

-- 值得一提的是如果您不会处理高版本Android系统的储存空间权限问题，请不要高于这个值
```

---

#### ** 调试模式 **
字段 `debugmode` 的作用：<br>
```lua
-- 以布尔值的形式指定该项目的是否激活调试模式
"debugmode": true -- 开
"debugmode": false -- 关

```

---

#### ** 使用权限 **
字段 `user_permission` 的作用：<br>
```lua
-- 以数组形式标注本项目时在 AndroidManifest.xml 内写入的应用权限
-- 如下代码指定了互联网权限和写入存储空间权限
"user_permission": [
"INTERNET",
"WRITE_EXTERNAL_STORAGE"
],

```

---

#### ** 编译模式 **
字段 `compilation` 的作用：<br>
```lua
-- 以 `布尔值` 的形式用于指定该项目的 `lua` 文件全部编译或者全部不进行编译
"compilation": true -- 全编译
"compilation": false -- 全不编译
```

---

#### ** 跳过编译 **
字段 `skip_compilation` 的作用：<br>
```lua
-- 以 `数组` 形式标注本项目个别文件的内容，用于跳过部分文件的编译，实现项目指定文件不进行编译
-- 例如这段代码用于跳过 main.lua 的编译
"skip_compilation": [
"main.lua",
]
```