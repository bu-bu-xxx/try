GLOBAL.setfenv(1, GLOBAL)

local strings = {
}

MergeTbale(STRINGS, strings)

local defaultlang = LanguageTranslator.defaultlang
if defaultlang and (defaultlang == "zh" or defaultlang == "zhr" or defaultlang == "zht") then
    local temp_lang = defaultlang .. "_temp"

	LanguageTranslator:LoadPOFile("languages/zh.po", temp_lang)
	MergeTbale(LanguageTranslator.languages[defaultlang], LanguageTranslator.languages[temp_lang], true)
    TranslateStringTable(STRINGS)
    LanguageTranslator.languages[temp_lang] = nil
    LanguageTranslator.defaultlang = defaultlang
end
