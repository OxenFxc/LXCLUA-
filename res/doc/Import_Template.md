### 导入模板介绍

---

`main.lua`、`manifest.json` 是必须文件

`Preview.png` 是选择性文件

模板为zip文件，模板名.zip，其中"模板名"用作Title

---

#### **1. main.lua**
添加以下代码(选择性添加)
```lua
activity.setTitle("AppName")
```
注意 `AppName(string)` 不要修改


---

#### **2. manifest.json**
必须添加的内容(`不要修改任何内容`)
```json
{
  "versionName": "1.0",
  "versionCode": "1",
  "uses_sdk": {
    "minSdkVersion": "23",
    "targetSdkVersion": "29"
  },
  "package": "PackageName",
  "application": {
    "label": "AppName",
    "debugmode": Debug
  },
  "user_permission": [
  "WRITE_EXTERNAL_STORAGE",
  "READ_EXTERNAL_STORAGE",
  "INTERNET"
  ],
  "compilation": true,
  "skip_compilation": [
  ]
}
```
注意 `PackageName(string)`、`AppName(string)`、`Debug(boolean)` 都不要修改

---

#### **3. Preview.png**
尺寸规格: `1080*1562`

`Preview.png` 此文件为模板的预览图文件，用于显示模板的大致布局