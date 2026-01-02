local _M = {}
local bindClass = luajava.bindClass
local Transliterator = bindClass "android.icu.text.Transliterator"

function _M.hanziToPinyin(str)
  local function convert(input)
    local pinyin = {
      ["ā"] = "a", ["á"] = "a", ["ǎ"] = "a", ["à"] = "a",
      ["ē"] = "e", ["é"] = "e", ["ě"] = "e", ["è"] = "e",
      ["ī"] = "i", ["í"] = "i", ["ǐ"] = "i", ["ì"] = "i",
      ["ō"] = "o", ["ó"] = "o", ["ǒ"] = "o", ["ò"] = "o",
      ["ū"] = "u", ["ú"] = "u", ["ǔ"] = "u", ["ù"] = "u",
      ["ǖ"] = "v", ["ǘ"] = "v", ["ǚ"] = "v", ["ǜ"] = "v",
      ["ü"] = "v", ["ń"] = "n", ["ň"] = "n", ["ǹ"] = "n",
      ["ḿ"] = "m", ["m̀"] = "m",
    }
    local result = ""
    for char in utf8.gmatch(input, ".[\128-\191]*") do
      if pinyin[char] then
        result = result .. pinyin[char]
       else
        result = result .. char
      end
    end
    return result
  end
  local content = Transliterator.getInstance("Han-Latin").transliterate(str):gsub(" ", "")
  return convert(content)
end

return _M