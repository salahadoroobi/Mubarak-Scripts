-- Mubarak Scripts | Experimental build
local APP_NAME = "Mubarak Scripts"
local DEVELOPER_NAME = "صلاح الدين الدروبي"
local APP_VERSION = "V0.0.1"
local APP_STATUS = "Experimental"





local SCRIPT_NAME = "القائمة الرئيسية | " .. APP_VERSION


-- ========================================================
-- 🟢 نهاية نظام الحماية
-- ========================================================

local original_choice = gg.choice
local original_multi = gg.multiChoice

-- دالة بناء الإطار للخيارات (معدلة لتدعم العربية من اليمين)
local function buildItemBox(text)
    local cleanText = text:gsub("^%s+", ""):gsub("%s+$", "")
    -- استخدام رموز عربية/زخرفية في البداية والنهاية لضمان اتجاه النص من اليمين
    local decorated = "『 " .. cleanText .. " 』"
    
    -- إزالة المسافات البادئة وإضافة خط فاصل بسيط
    return "ᰔᩚ " .. decorated .. " ᰔᩚ"
end

-- 1. تعديل القوائم العادية (gg.choice)
gg.choice = function(items, selected, title)
    if not items then return nil end
    local styledItems = {}
    for _, v in ipairs(items) do
        table.insert(styledItems, buildItemBox(v))
    end
    
    local cleanTitle = title or "لوحة التحكم"
    cleanTitle = cleanTitle:gsub("[დ]", ""):gsub("^%s*(.-)%s*$", "%1")
    if cleanTitle == "" then cleanTitle = "القائمة" end
    
    -- إزالة المسافات من الترويسة لتظهر من اليمين
    local header = 
        "╔════════════════════════════════╗\n" ..
        "   🇲 🇺 🇧 🇦 🇷 🇦 🇰  🇦 🇱 🇦 🇹 🇲 🇮   \n" ..
        "╚════════════════════════════════╝\n" ..
        "   ✿ " .. cleanTitle .. " ✿"

    return original_choice(styledItems, selected, header)
end

-- 2. تعديل قوائم الاختيار المتعدد (gg.multiChoice)
gg.multiChoice = function(items, selected, title)
    if not items then return nil end
    local styledItems = {}
    for _, v in ipairs(items) do
        local cleanText = v:gsub("^%s+", ""):gsub("%s+$", "")
        -- وضع علامة الاختيار في بداية النص (ستظهر على اليمين تلقائياً)
        table.insert(styledItems, "☑ " .. cleanText)
    end
    
    local cleanTitle = title or "الاختيار المتعدد"
    cleanTitle = cleanTitle:gsub("[❁✿]", ""):gsub("^%s*(.-)%s*$", "%1")
    
    local header = 
        "╔════════════════════════════════╗\n" ..
        "   🇲 🇺 🇧 🇦 🇷 🇦 🇰  🇦 🇱 🇦 🇹 🇲 🇮   \n" ..
        "╚════════════════════════════════╝\n" ..
        "   ✿ " .. cleanTitle .. " ✿"

    return original_multi(styledItems, selected, header)
end
-- ═══════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════
local cooperationValue_global = nil
local cityMissionValue = nil
-- ═══════════════════════════════════════════════════════════
-- 1) البيانات المحفوظة
-- ═══════════════════════════════════════════════════════════
local savedData = {
    replaceAddresses = {},
    monitorAddress1  = nil,
    monitorAddress2  = nil,
    boxAddress       = nil,
    productCount     = 1,
    isUpdated        = false
}

local monitoring         = false
local currentItemsList   = {}
local currentItemsCount  = 0
local currentItemIndex   = 1
local currentItemName    = ""
local currentNeedCount   = 1
local lastMonitor1       = 0
local currentMenuFn      = nil

local showMainMenu, showMenuB, showCardPacksMenu, showCardsSectionMenu
local showCashMenu, showCityDecorMenu, showPlaneDecorMenu
local showBuildMenu, showBanDecorMenu, showLevelMenu, cityDevelopment
local showPlaneTrainMenu, showRaceMenu, showCopyPointersMenu
local Haie, showTrainDecorMenu, showFenceDecorMenu


local function loadData()
    savedData.replaceAddresses = {}
    savedData.monitorAddress1  = nil
    savedData.monitorAddress2  = nil
    savedData.boxAddress       = nil
    savedData.productCount     = 1
    savedData.isUpdated        = false
    savedData.boxType          = 29   -- 🆕 الافتراضي 29
end

-- ═══════════════════════════════════════════════════════════
-- 3) دوال المراقبة والتبديل الأساسية
-- ═══════════════════════════════════════════════════════════
local function getMonitor1()
    if savedData.monitorAddress1 then
        return gg.getValues({{address = savedData.monitorAddress1, flags = gg.TYPE_DWORD}})[1].value
    end
    return 0
end

local function getMonitor2()
    if savedData.monitorAddress2 then
        return gg.getValues({{address = savedData.monitorAddress2, flags = gg.TYPE_DWORD}})[1].value
    end
    return 0
end

local function setMonitor2(v)
    if savedData.monitorAddress2 then
        gg.setValues({{address = savedData.monitorAddress2, flags = gg.TYPE_DWORD, value = v}})
    end
end

local function applyItem(itemValues, count)
    if not savedData.isUpdated or #savedData.replaceAddresses < 6 then return false end
    if savedData.boxAddress then
        gg.setValues({
            {address = savedData.boxAddress + 0x1D8, flags = gg.TYPE_DWORD, value = 0},
            {address = savedData.boxAddress + 0x1DC, flags = gg.TYPE_DWORD, value = count}
        })
    end
    local mods = {}
    for i = 1, 6 do
        mods[i] = {address = savedData.replaceAddresses[i], flags = gg.TYPE_DWORD, value = itemValues[i] or 0}
    end
    gg.setValues(mods)
    return true
end

local function askProductCount()
    local input = gg.prompt({"🔢 أدخل عدد المنتج:"}, {""}, {"number"})
    if input == nil then gg.toast("❌ تم الإلغاء"); return nil end
    local n = tonumber(input[1])
    if not n or n <= 0 then gg.toast("❌ عدد غير صالح"); return nil end
    return n
end

-- 🆕 سؤال المستخدم عن الصندوق (29 أو 28)
local function askBoxType()
    local choice = gg.choice({
        "📦 الاستبدال عبر الصندوق 29",
        "📦 الاستبدال عبر الصندوق 28",
        "❌ إلغاء"
    }, nil, "🎁 اختر الصندوق الذي تريد الاستبدال عبره")
    if not choice or choice == 3 then return nil end
    return choice == 1 and 29 or 28
end

local updateReplacementValues
local isStickersMode = false   -- 🆕 للتمييز بين الملصقات وغيرها


local function resolveItemValues(item)
    if not item then return nil end
    if item.values then return item.values end
    if not item.address then return nil end

    gg.clearResults()
    gg.loadResults({{address = item.address, flags = gg.TYPE_QWORD}})
    gg.searchPointer(0)
    local ptrs = gg.getResults(10)
    gg.clearResults()
    if #ptrs == 0 then return nil end

    local ptr = ptrs[1].address
    local src = gg.getValues({
        {address = ptr - 0x10, flags = gg.TYPE_DWORD},
        {address = ptr - 0xC,  flags = gg.TYPE_DWORD},
        {address = ptr - 0x8,  flags = gg.TYPE_DWORD},
        {address = ptr - 0x4,  flags = gg.TYPE_DWORD},
        {address = ptr,        flags = gg.TYPE_DWORD},
        {address = ptr + 0x4,  flags = gg.TYPE_DWORD}
    })
    return {src[1].value, src[2].value, src[3].value, src[4].value, src[5].value, src[6].value}
end

local function startSequentialReplacement(itemsList, fixedCount, stickersMode)
    isStickersMode = (stickersMode == true)

    -- 🆕 السؤال عن نوع الصندوق قبل كل استبدال
    local boxType = askBoxType()
    if not boxType then gg.toast("❌ تم الإلغاء"); return false end
    if savedData.boxType ~= boxType then
        savedData.isUpdated = false   -- إجبار إعادة البحث عند تغيير الصندوق
    end
    savedData.boxType = boxType

    if not savedData.isUpdated or #savedData.replaceAddresses < 6 then
        gg.toast("🔍 جاري استبدال النتائج...")
        if not updateReplacementValues() then
            gg.alert("⚠️ فشل تحديث قيم الاستبدال\n\nتأكد من فتح اللعبة ثم أعد المحاولة")
            return false
        end
    end
    if not itemsList or #itemsList == 0 then gg.toast("❌ لا توجد عناصر"); return false end
    local countToSet
    if fixedCount == true then
        countToSet = askProductCount(); if countToSet == nil then return false end
    elseif fixedCount == "six" then
        countToSet = askProductCount(); if countToSet == nil then return false end
    elseif type(fixedCount) == "number" and fixedCount > 0 then
        countToSet = fixedCount
    else countToSet = 1 end
    currentNeedCount = countToSet; savedData.productCount = countToSet
    monitoring = true; currentItemsList = itemsList; currentItemsCount = #itemsList
    currentItemIndex = 1; currentItemName = itemsList[1].name
    local firstVals = resolveItemValues(itemsList[1])
if not firstVals then
    gg.alert("⚠️ فشل جلب قيم العنصر الأول\n\nتأكد من فتح اللعبة")
    return false
end
applyItem(firstVals, countToSet)
    lastMonitor1 = getMonitor1(); setMonitor2(2)
    gg.toast("🎯 " .. currentItemName .. " (1/" .. currentItemsCount .. ")")

    -- ✅ إشعار البدء — النص ديناميكي حسب الصندوق المختار
    gg.alert(
        "✅ تم التبديل بنجاح!\n\n" ..
        "━━━━━━━━━━━━━━━━━━━━━\n" ..
        "🎁 افتح التصريح \n" ..
        "🎯 استلم الهدية " .. savedData.boxType .. " الى ان يتم استلام الهدايا كامله \n" ..
        "━━━━━━━━━━━━━━━━━━━━━\n\n" ..
        "📊 العنصر الحالي: " .. currentItemName .. "\n" ..
        "🔢 التقدم: (1/" .. currentItemsCount .. ")\n\n" ..
        "⏳ بعد الاستلام سيتم التبديل تلقائياً للعنصر التالي",
        "🚀 فهمت - ذاهب للاستلام"
    )
    return true
end

-- ═══════════════════════════════════════════════════════════
-- 🆕 نظام القوالب المضغوطة
-- ═══════════════════════════════════════════════════════════
local function expandTemplate(template, items)
    local result = {}
    for _, item in ipairs(items) do
        local values = {}
        local vi = 1
        -- 🔧 دعم v مفرد أو directValues
        local dyn = item.directValues or (item.v ~= nil and {item.v}) or {}
        for i = 1, 6 do
            if template[i] == "?" then
                values[i] = dyn[vi] or 0
                vi = vi + 1
            else
                values[i] = template[i] or 0
            end
        end
        result[#result + 1] = {name = item.name, values = values}
    end
    return result
end

local function expandMultiTemplate(groups)
    local result = {}
    for _, g in ipairs(groups) do
        local expanded = expandTemplate(g.template, g.items)
        for _, item in ipairs(expanded) do
            result[#result + 1] = item
        end
    end
    return result
end

-- ═══════════════════════════════════════════════════════════
-- 🌟 الدالة العامة لكل المجموعات (بديل موحد للاستدعاءات)
-- ═══════════════════════════════════════════════════════════

function runGroup(config)
    if not config or not config.list or #config.list == 0 then
        gg.alert("⚠️ القائمة فارغة", "حسناً"); return
    end

    local finalList = config.list

    -- 🔹 إذا كانت القائمة أكثر من عنصر، اعرض خيارات الكل/يدوي
    if #config.list > 1 then
        local mode = gg.choice({
            "↩️ رجوع",
            "🔄 تبديل الكل (" .. #config.list .. ")",
            "☑️ اختيار يدوي",
            "❌ إلغاء"
        }, nil, config.title or "اختر طريقة التبديل")

        if not mode or mode == 1 or mode == 4 then return end

        if mode == 3 then
            local display = {}
            for i, p in ipairs(config.list) do display[i] = p.name end
            local sel = gg.multiChoice(display, nil, "☑️ اختر ما تريد تبديله")
            if not sel then return end

            finalList = {}
            for i, p in ipairs(config.list) do
                if sel[i] then finalList[#finalList+1] = p end
            end
            if #finalList == 0 then gg.toast("⚠️ لم تختر شيئاً"); return end
        end
    end

    -- 🔹 تحديد عدد المنتج
    local countArg
    if config.askCount then
        countArg = "six"                              -- يسأل المستخدم
    elseif type(config.fixedCount) == "number" then
        countArg = config.fixedCount                  -- عدد ثابت
    else
        countArg = false                              -- افتراضي = 1
    end

    startSequentialReplacement(finalList, countArg, config.stickersMode == true)
end

local function checkAndReplace()
    if not monitoring then return end
    local m1 = getMonitor1()
    if m1 == 65543 and lastMonitor1 ~= 65543 then
        gg.toast("✅ " .. currentItemName .. " (" .. currentItemIndex .. "/" .. currentItemsCount .. ")")
        currentItemIndex = currentItemIndex + 1
if currentItemIndex <= currentItemsCount then
    currentItemName = currentItemsList[currentItemIndex].name
    local nextVals = resolveItemValues(currentItemsList[currentItemIndex])
    if nextVals then
        applyItem(nextVals, currentNeedCount)
        setMonitor2(2)
        gg.toast("📦 " .. currentItemName .. " (" .. currentItemIndex .. "/" .. currentItemsCount .. ")")
    else
        monitoring = false
        currentItemsList = {}; currentItemsCount = 0; currentItemIndex = 1
        gg.alert(
            "⚠️ فشل جلب القيم للعنصر:\n" .. currentItemName ..
            "\n\n❌ تم إيقاف التبديل التلقائي",
            "حسناً"
        )
        return
    end
else
            monitoring = false
            currentItemsList = {}; currentItemsCount = 0; currentItemIndex = 1
            if isStickersMode then
                -- 🌟 إشعار خاص بالملصقات
                isStickersMode = false
                gg.alert(
                    "🎉 اكتمل استبدال جميع الملصقات بنجاح!\n\n" ..
                    "━━━━━━━━━━━━━━━━━━━━━\n" ..
                    "⚠️ خطوة أخيرة مهمة:\n" ..
                    "━━━━━━━━━━━━━━━━━━━━━\n\n" ..
                    "1️⃣ الملصقات لن تظهر مباشرة في اللعبة\n\n" ..
                    "2️⃣ أغلق اللعبة تماماً من قائمة التطبيقات\n\n" ..
                    "3️⃣ افتحها من جديد\n\n" ..
                    "4️⃣ ستجد جميع الملصقات في مجموعتك ✨\n\n" ..
                    "💡 انتظر تحميل اللعبة كاملاً قبل التحقق",
                    "✅ فهمت"
                )
            else
                gg.alert(
                    "🎉 اكتمل الاستبدال بنجاح!\n\n✅ تم تبديل جميع العناصر المحددة",
                    "✅ ممتاز"
                )
            end
        end
    else
        if m1 ~= lastMonitor1 then setMonitor2(2) end
    end
    lastMonitor1 = m1
end



updateReplacementValues = function()
    gg.setVisible(false); gg.clearResults()
    gg.toast("🔍 جاري البحث عن الصندوق...")

    -- 🆕 اختيار الرقم والتحقق حسب نوع الصندوق
    local boxType   = savedData.boxType or 29
    local searchNum = (boxType == 28) and "1379101978" or "1970225964"
    local checkVal  = boxType  -- 28 أو 29

    gg.searchNumber(searchNum, gg.TYPE_DWORD)
    local results = gg.getResults(1000)
    if #results == 0 then
        gg.toast("❌ لم يتم العثور على الهدية " .. boxType ..
                 " اذا لم قم بتفعيل التصريح او تحقق من نطاقات الذاكره وحاول مجددا")
        return false
    end

    local foundBox = nil
    for _, v in ipairs(results) do
        local check = gg.getValues({
            {address = v.address + 0x1B0,  flags = gg.TYPE_DWORD},
            {address = v.address + 0x1BC, flags = gg.TYPE_DWORD}
        })
        if check[1].value == checkVal and (check[2].value == 1 or check[2].value == 2) then
            foundBox = v.address; break
        end
    end
    gg.clearResults()
    if not foundBox then gg.toast("❌ لم يتم التحقق من الشروط"); return false end

    savedData.boxAddress       = foundBox
    savedData.monitorAddress1  = foundBox - 0x18
    savedData.monitorAddress2  = foundBox + 0x1BC
    savedData.replaceAddresses = {
        foundBox + 0x1C0, foundBox + 0x1C4, foundBox + 0x1C8,
        foundBox + 0x1CC, foundBox + 0x1D0, foundBox + 0x1D4
    }
    gg.setValues({
        {address = foundBox + 0x1D8, flags = gg.TYPE_DWORD, value = 0},
        {address = foundBox + 0x1DC, flags = gg.TYPE_DWORD, value = 1}
    })
    savedData.productCount = 1; savedData.isUpdated = true
    gg.toast("✅ تم استعادة الهدية " .. boxType .. " بنجاح")
    return true
end

-- ═══════════════════════════════════════════════════════════
-- 4) دالة البحث والانتقال الذكية (Shift System)
-- ═══════════════════════════════════════════════════════════
local function prepareShiftItems(searchStr, shiftOffset, itemName)
    gg.setVisible(false); gg.clearResults()
    gg.toast("🔍 جاري البحث عن " .. itemName .. "...")

    gg.searchNumber(tostring(searchStr), gg.TYPE_DWORD)
    local count = gg.getResultsCount()
    if count == 0 then gg.toast("❌ لا توجد نتائج للبحث"); return nil end
    if count > 20000 then gg.toast("⚠️ نتائج كثيرة جداً"); return nil end

    local results = gg.getResults(count)
    gg.clearResults()

    for i = 1, #results do
        results[i].address = results[i].address + shiftOffset
    end

    -- فلتر القيمتين السابقتين = 0
    local checkList = {}
    for _, r in ipairs(results) do
        checkList[#checkList+1] = {address = r.address - 0x4, flags = gg.TYPE_DWORD}
        checkList[#checkList+1] = {address = r.address - 0x8, flags = gg.TYPE_DWORD}
    end
    local checkVals = gg.getValues(checkList)

    local validAddrs = {}
    for i, r in ipairs(results) do
        if checkVals[(i-1)*2+1].value == 0 and checkVals[(i-1)*2+2].value == 0 then
            validAddrs[#validAddrs+1] = r.address
        end
    end

    if #validAddrs == 0 then
        gg.toast("❌ لا نتائج تطابق شرط الصفر بعد الانتقال")
        return nil
    end

    -- قراءة القيم الست لكل عنوان
    local extractList = {}
    for _, addr in ipairs(validAddrs) do
        for k = 0, 5 do
            extractList[#extractList+1] = {address = addr + k*4, flags = gg.TYPE_DWORD}
        end
    end
    local extracted = gg.getValues(extractList)

    -- فحص: رفض أي قيمة سالبة + اشتراط موجب للقيمتين الأولى والثانية
    local products = {}
    local rejected, rejectedNegative = 0, 0
    for i, addr in ipairs(validAddrs) do
        local prod = {}
        for k = 1, 6 do prod[k] = extracted[(i-1)*6 + k].value end

        local hasNegative = false
        for k = 1, 6 do
            if prod[k] < 0 then hasNegative = true; break end
        end

        if hasNegative then
            rejectedNegative = rejectedNegative + 1
        elseif prod[1] > 0 and prod[2] > 0 then
            products[#products+1] = { values = prod }
        else
            rejected = rejected + 1
        end
    end

    if #products == 0 then
        local m = "❌ لا نتائج صالحة"
        if rejectedNegative > 0 then m = m .. " (🚫 سالبة: " .. rejectedNegative .. ")" end
        if rejected > 0         then m = m .. " (⚠️ غير صالحة: " .. rejected .. ")"         end
        gg.toast(m)
        return nil
    end

    -- إزالة التكرار
    local unique = {}
    for _, prod in ipairs(products) do
        local dup = false
        for _, kept in ipairs(unique) do
            local diff = 0
            for k = 1, 6 do if prod.values[k] ~= kept.values[k] then diff = diff + 1 end end
            if diff == 0 then dup = true; break end
        end
        if not dup then unique[#unique+1] = prod end
    end

    if #unique == 0 then gg.toast("❌ لا نتائج فريدة"); return nil end

    -- ملخص + سؤال المستخدم: اختيار يدوي أم تبديل مباشر
    local summary = "📋 " .. itemName .. "\n\n"
    summary = summary .. "✅ صالحة وفريدة: " .. #unique
    if rejectedNegative > 0 then summary = summary .. "\n🚫 رُفضت سالبة: " .. rejectedNegative end
    if rejected         > 0 then summary = summary .. "\n⚠️ غير صالحة: "   .. rejected         end
    summary = summary .. "\n\n🎯 كيف تريد المتابعة؟"

    local mode = gg.choice({
        "☑️ اختيـــار يـــدوي (تحديـــد مـــا أريـــد)",
        "⚡ تبـــديل مباشـــر للكـــل (" .. #unique .. ")",
        "❌ إلغـــاء",
    }, nil, summary)

    if not mode or mode == 3 then gg.toast("❌ تم الإلغاء"); return nil end

    -- ─── الوضع 1: تبديل مباشر للكل ───
    if mode == 2 then
        local finalItems = {}
        for i, p in ipairs(unique) do
            finalItems[#finalItems+1] = {
                name   = "🎁 " .. itemName .. " " .. i,
                values = p.values,
            }
        end
        gg.toast("⚡ تبديل مباشر: " .. #finalItems .. " عنصر")
        return finalItems
    end

    -- ─── الوضع 2: اختيار يدوي ───
    local displayItems = {}
    for i, p in ipairs(unique) do
        displayItems[i] = "#" .. i .. "  " .. table.concat(p.values, ";")
    end

    local selections = gg.multiChoice(displayItems, nil,
        "☑️ حدّد النتائج التي تريد تبديلها\n(" .. #unique .. " نتيجة متاحة)")
    if not selections then gg.toast("❌ تم الإلغاء"); return nil end

    local finalItems = {}
    for i, p in ipairs(unique) do
        if selections[i] then
            finalItems[#finalItems+1] = {
                name   = "🎁 " .. itemName .. " " .. #finalItems+1,
                values = p.values,
            }
        end
    end

    if #finalItems == 0 then
        gg.toast("⚠️ لم يتم تحديد أي نتيجة"); return nil
    end

    gg.toast("✅ تم تحديد " .. #finalItems .. " من " .. #unique)
    return finalItems
end

-- ═══════════════════════════════════════════════════════════
-- 5) الكاش والقسائم
-- ═══════════════════════════════════════════════════════════
local cashEventItems = {
    {name = "💶 العملات الخضراء",          values = {1935762184, 104, 0, 0, 0, 0}, count = true},
    {name = "💰 العملات الصفراء",          values = {1768907530, 29550, 0, 0, 0, 0}, count = true},
    {name = "🪙 عملات سباق اليخت",         values = {1734693396, 1130460257, 6845281, 0, 0, 0}, count = true},
    {name = "💎 نقاط الثروة المتجمدة",     values = {1634878494, 1315860327, 1416917861, 1852140399, 0, 0}, count = true},
    {name = "🌸 خرز أزهار طنين",           values = {1634882594, 1867148905, 1701737077, 1802458233, 28261, 0}, count = true},
    {name = "🎪 نقاط حدث المغامرة",        values = {1886938400, 1953064037, 1164865385, 1735550318, 121, 0}, count = true}
}

function Haie()
    currentMenuFn = Haie
    local items = {
        "💳 قســـــــائم المساعـــده",
        "🏪 قســـــــائم ترقيـــة الشونـــة",
        "📐 قســـــــائم التوســـعه",
        "🚂 قســـــــائم ترقيـــة القطـــارات",
        "🏝️ قســـــــائم ترقيـــة الجـــزر",
        "🏭 قســـــــائم ترقيـــة المصانـــع",
        "🔙 رجـــــــــــــــــــــــــــــــــوع"
    }
    local menu = gg.choice(items, nil, "🎁 قسائم الترقيات")
    if not menu then return end

    local function doReplace(name, values)
    runGroup({
        list         = {{name = name, values = values}},
        title        = "🎁 " .. name,
        askCount     = true,
        stickersMode = true         -- القسائم كانت true في الأصل
    })
end

    if menu == 1 then doReplace("💳 قسائم المساعده", {1970225964, 1282305904, 1415864687, 1852399986, 1886546241, 7631471})
    elseif menu == 2 then doReplace("🏪 قسائم ترقية الشونة", {1701996058, 1886930277, 1769172577, 28271, 1701996058, 1886930277})
    elseif menu == 3 then doReplace("📐 قسائم التوسعه", {1701996058, 1886930277, 1769172577, 28271, 1701996058, 1886930277})
    elseif menu == 4 then doReplace("🚂 قسائم ترقية القطارات", {1970225956, 1433300848, 1634887536, 1918133604, 7235937, 0})
    elseif menu == 5 then doReplace("🏝️ قسائم ترقية الجزر", {1970225958, 1433300848, 1634887536, 1934189924, 1684955500, 0})
    elseif menu == 6 then doReplace("🏭 قسائم ترقية المصانع", {1970225960, 1433300848, 1634887536, 1632003428, 1919906915, 121})
    elseif menu == 7 then currentMenuFn = showMenuB; return showMenuB() end
end

-- ═══════════════════════════════════════════════════════════
-- 6) مغلفات الكروت
-- ═══════════════════════════════════════════════════════════
local cardPacksItems = {
    {name = "📸 مغلفات الصور (برقم معين)", values = {1918976790, 1348420452, 896230241, 0, 0, 0}, count = true},
    {name = "🖼️ مغلفات الصور (48 ثابت)",   values = {1918976790, 1348420452, 896230241, 0, 0, 0}, count = 48}
}

-- ═══════════════════════════════════════════════════════════
-- 7) زينة القطار المعقدة
-- ═══════════════════════════════════════════════════════════
local trainDecorationsList = {

    {name = "🌸 محطة الزهور", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1701207918},{offset = 0x14, value = 1986622579}}},
    {name = "⚔️ محطة الأسطورة", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1701338990},{offset = 0x14, value = 1935764588}}},
    {name = "🎭 محطة المسرحية", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1752457070},{offset = 0x14, value = 1920229733}}},
    {name = "🏚️ مستوطنة قديمة", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1919967086},{offset = 0x14, value = 1936287845}}},
    {name = "🐰 محطة عيد الفصح", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1634033518},{offset = 0x14, value = 1919251571}}},
    {name = "🎵 مركز التسجيل", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1869766510},{offset = 0x14, value = 1919839075}}},
    {name = "🎂 محطة عيد ميلاد", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1751342958},{offset = 0x14, value = 1953720690},{offset = 0x18, value = 846422381}}},
    {name = "🎁 قطار عيد ميلاد", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1935764852},{offset = 0x14, value = 875704370}}},
    {name = "🪖 محطة معسكر التدريب", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1869766510},{offset = 0x14, value = 1215195490}}},
    {name = "🎄 محطة الكريسماس", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1751342958},{offset = 0x14, value = 1953720690},{offset = 0x18, value = 7561581}}},
    {name = "🥂 محطة غاتسبي", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1632067438},{offset = 0x14, value = 2036495220}}},
    {name = "🏰 محطة القلعة", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1852530542},{offset = 0x14, value = 1952999273}}},
    {name = "🏮 محطة صينية", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1970036590},{offset = 0x14, value = 1316118894}}},
    {name = "🤠 محطة رعاة البقر", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1702322030},{offset = 0x14, value = 1919251571}}},
    {name = "🎃 محطة الهالوين", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1634230126},{offset = 0x14, value = 2003790956}}},
    {name = "👻 قطار الهالوين", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1751084649},{offset = 0x14, value = 1869376609}}},
    {name = "🇫🇷 محطة الفرنسي", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1919311726},{offset = 0x14, value = 1701015137}}},
    {name = "⭐ محطة المشاهير", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1701011310},{offset = 0x14, value = 1919051116}}},
    {name = "⭐ قطار المشاهير", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 2037672306},{offset = 0x14, value = 3356511}}},
    {name = "🚄 محطة بوابة القطار السريع", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1347641198},{offset = 0x14, value = 846790706}}},
    {name = "🛤️ محطة السكة الحديدية", search = true, checks = {{offset = -0x4, value = 0},{offset = 0x10, value = 1953062766},{offset = 0x14, value = 846818401}}}
 

}

-- ═══════════════════════════════════════════════════════════
-- 🔍 دالة بحث جماعي عامة (للقطارات واللافتات وأي مجموعة)
-- ═══════════════════════════════════════════════════════════
local function resolveGroupDecorations(config)
    local list          = config.list or {}
    local searchNumbers = config.searchNumbers or {}
    local keyOffsets    = config.keyOffsets or {}
    local extraOffsets  = config.extraOffsets or {}
    local disambOffset  = config.disambOffset
    local label         = config.label or "عنصر"

    local hasSearch = false
    for _, item in ipairs(list) do
        if not item.values and item.search then hasSearch = true; break end
    end
    if not hasSearch then return list end
    if #searchNumbers == 0 or #keyOffsets == 0 then return list end

    gg.setVisible(false); gg.clearResults()
    gg.toast("🔍 البحث الجماعي عن " .. label .. "...")

    local allAddrs = {}
    for _, num in ipairs(searchNumbers) do
        gg.searchNumber(tostring(num), gg.TYPE_DWORD)
        local r = gg.getResults(gg.getResultsCount())
        for _, v in ipairs(r) do allAddrs[#allAddrs + 1] = v.address end
        gg.clearResults()
    end
    if #allAddrs == 0 then gg.toast("❌ لا نتائج للبحث"); return nil end

    local chk4 = {}
    for i, a in ipairs(allAddrs) do
        chk4[i] = {address = a - 0x4, flags = gg.TYPE_DWORD}
    end
    local v4 = gg.getValues(chk4)
    local valid = {}
    for i, a in ipairs(allAddrs) do
        if v4[i].value == 0 then valid[#valid + 1] = a end
    end
    gg.clearResults()
    if #valid == 0 then gg.toast("❌ لا نتائج تحقق -0x4=0"); return nil end

    local allReadOffsets = {}
    for _, off in ipairs(keyOffsets)   do allReadOffsets[#allReadOffsets + 1] = off end
    for _, off in ipairs(extraOffsets) do allReadOffsets[#allReadOffsets + 1] = off end

    local reads = {}
    for _, addr in ipairs(valid) do
        for _, off in ipairs(allReadOffsets) do
            reads[#reads + 1] = {address = addr + off, flags = gg.TYPE_DWORD}
        end
    end
    local vals   = gg.getValues(reads)
    local numKey = #keyOffsets
    local numExt = #extraOffsets
    local total  = numKey + numExt

    local addrMap = {}
    for i, addr in ipairs(valid) do
        local base = (i - 1) * total
        local parts = {}
        for k = 1, numKey do
            parts[#parts + 1] = tostring(vals[base + k].value)
        end
        local key = table.concat(parts, "_")
        local disambVal
        if disambOffset then
            for k = 1, numExt do
                if extraOffsets[k] == disambOffset then
                    disambVal = vals[base + numKey + k].value
                    break
                end
            end
        end
        if not addrMap[key] then addrMap[key] = {} end
        table.insert(addrMap[key], {addr = addr, disamb = disambVal})
    end

    local output, failedNames, successCount = {}, {}, 0
    for _, item in ipairs(list) do
        if item.values then
            output[#output + 1] = {name = item.name, values = item.values}
        elseif item.search then
            local keyVals = {}
            local disambVal
            for _, c in ipairs(item.checks or {}) do
                local isKey = false
                for k, off in ipairs(keyOffsets) do
                    if c.offset == off then keyVals[k] = c.value; isKey = true; break end
                end
                if not isKey and disambOffset and c.offset == disambOffset then
                    disambVal = c.value
                end
            end

            local parts = {}
            for k = 1, numKey do parts[#parts + 1] = tostring(keyVals[k] or 0) end
            local key = table.concat(parts, "_")

            local arr = addrMap[key]
            local foundAddr
            if arr and #arr > 0 then
                if disambVal then
                    local idx
                    for i, e in ipairs(arr) do
                        if e.disamb == disambVal then idx = i; break end
                    end
                    if idx then
                        foundAddr = arr[idx].addr
                        table.remove(arr, idx)
                    end
                else
                    foundAddr = arr[1].addr
                    table.remove(arr, 1)
                end
            end

            if foundAddr then
                gg.clearResults()
                gg.loadResults({{address = foundAddr, flags = gg.TYPE_QWORD}})
                gg.searchPointer(0)
                local ptrs = gg.getResults(10)
                gg.clearResults()
                if #ptrs > 0 then
                    local ptr = ptrs[1].address
                    local src = gg.getValues({
                        {address = ptr - 0x10, flags = gg.TYPE_DWORD},
                        {address = ptr - 0xC,  flags = gg.TYPE_DWORD},
                        {address = ptr - 0x8,  flags = gg.TYPE_DWORD},
                        {address = ptr - 0x4,  flags = gg.TYPE_DWORD},
                        {address = ptr,        flags = gg.TYPE_DWORD},
                        {address = ptr + 0x4,  flags = gg.TYPE_DWORD}
                    })
                    output[#output + 1] = {
                        name = item.name,
                        values = {src[1].value, src[2].value, src[3].value,
                                  src[4].value, src[5].value, src[6].value}
                    }
                    successCount = successCount + 1
                else
                    failedNames[#failedNames + 1] = item.name
                end
            else
                failedNames[#failedNames + 1] = item.name
            end
        end
    end

    gg.clearResults()
    if successCount > 0 then gg.toast("✅ تم تحديد " .. successCount .. " " .. label) end
    if #failedNames > 0 then gg.toast("⚠️ فشل " .. #failedNames .. " عنصر") end
    return output
end



local function resolveTrainDecorations()
    return resolveGroupDecorations({
        list          = trainDecorationsList,
        searchNumbers = {1852402515},
        keyOffsets    = {0x10, 0x14},
        extraOffsets  = {0x18},
        disambOffset  = 0x18,
        label         = "محطة"
    })
end

local citySignsList = {
    {name = "🎸 لافتة مدينة الروك",                    search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1918856807},{offset = 0x10, value = 1600873327},{offset = 0x14, value = 1852270963}}},
    {name = "🍬 لافتة العلكة للجميع",                  search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1918856807},{offset = 0x10, value = 1852403061},{offset = 0x14, value = 1601465953}}},
    {name = "👾 لافتة وحش مطاطية",                     search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1717530215},{offset = 0x10, value = 1802396018},{offset = 0x14, value = 1818323039}}},
    {name = "🎄 علامة المدينة في عيد الميلاد",          search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1667198567},{offset = 0x10, value = 1936290408},{offset = 0x14, value = 1935764852}}},
    {name = "🎅 لافتة بطابع عيد الميلاد",               search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1398763111},{offset = 0x10, value = 959930192},{offset = 0x14, value = 1769168688}}},
    {name = "🎂 لافتة الذكرى السنوية للمدينة",          search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1650421351},{offset = 0x10, value = 1752461929},{offset = 0x14, value = 1601790308},{offset = 0x18, value = 1702441009}}},
    {name = "🏡 لافتة مزرعة قديمة رائعة",              search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1667198567},{offset = 0x10, value = 1935636335},{offset = 0x14, value = 7235433}}},
    {name = "🥤 لافتة كشك المشروبات",                  search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1935634023},{offset = 0x10, value = 1953460077},{offset = 0x14, value = 1650813288}}},
    {name = "⛸️ لافتة تزلج على الجليد للمدينة",          search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1935634023},{offset = 0x10, value = 1651994478},{offset = 0x14, value = 1685217647}}},
    {name = "🍪 السيد بسكويت الزنجبيل",                 search = 1735289159, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1867017825},{offset = 0x10, value = 1869103988},{offset = 0x14, value = 1634496355}}},
    {name = "🍎 لافتة مدينة التفاحة الكبيرة",          search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1751084647},{offset = 0x10, value = 1702261345},{offset = 0x14, value = 1935635571}}},
    {name = "🌃 لافتة المدينة التي لا تنام",           search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1683975783},{offset = 0x10, value = 1868788585},{offset = 0x14, value = 1953063775}}},
    {name = "⚙️ لافتة مدينة ميكانيكية",                search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1834970727},{offset = 0x10, value = 1634231141},{offset = 0x14, value = 1600350574}}},
    {name = "🦄 لافتة مدينة بطابع خيالي",               search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1633644135},{offset = 0x10, value = 1768055154},{offset = 0x14, value = 1769168739}}},
    {name = "🏭 لافتة مدينة ذات مطحنة",                search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1298099815},{offset = 0x10, value = 1399614569},{offset = 0x14, value = 7235433}}},
    {name = "🪨 علامة المدينة الحجرية",                search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1935634023},{offset = 0x10, value = 1701736308},{offset = 0x14, value = 1734964063}}},
    {name = "🏛️ لافتة التقاليد القديمة",              search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1633644135},{offset = 0x10, value = 1851877747},{offset = 0x14, value = 1734964063}}},
    {name = "💭 علامة مدينة الأحلام",                  search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1767861863},{offset = 0x10, value = 1702260588},{offset = 0x14, value = 1734964063}}},
    {name = "💡 علامة مدينة الأضواء",                  search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1985965671},{offset = 0x10, value = 1935763301},{offset = 0x14, value = 1734964063}}},
    {name = "🌾 لافتة مزرعة مريحة",                    search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1717530215},{offset = 0x10, value = 1601008225},{offset = 0x14, value = 1852270963}}},
    {name = "🎉 شعار عيد مدينة",                       search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1650421351},{offset = 0x10, value = 1752461929},{offset = 0x14, value = 1601790308},{offset = 0x18, value = 1852270963}}},
    {name = "🎃 علامة هالوين كبيرة",                   search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1751084647},{offset = 0x10, value = 1869376609},{offset = 0x14, value = 1852138871}}},
    {name = "🤠 علامة مدينة الغرب البري",              search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 2002742887},{offset = 0x10, value = 1600416873},{offset = 0x14, value = 1953719671}}},
    {name = "💡 لافتة نيون للمدينة",                   search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1851747943},{offset = 0x10, value = 1601072997},{offset = 0x14, value = 1852270963}}},
    {name = "📢 لافتة إعلانية",                        search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1818193511},{offset = 0x10, value = 1601203553},{offset = 0x14, value = 1918988130}}},
    {name = "🎶 علامة المدينة الموسيقية",              search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1834970727},{offset = 0x10, value = 1667855221},{offset = 0x14, value = 1734964063}}},
    {name = "✨ لافتة المدينة الرائعة",                search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 2002742887},{offset = 0x10, value = 1701080943},{offset = 0x14, value = 1769168750}}},
    {name = "🌸 لافتة المدينة الزهرية",                search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1717530215},{offset = 0x10, value = 1702326124},{offset = 0x14, value = 1684365938}}},
    {name = "🎨 لافتة المدينة الفنية",                 search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1230990951},{offset = 0x10, value = 1131310962},{offset = 0x14, value = 1400468585}}},
    {name = "🌵 لافتة صبار للمدينة",                   search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1667198567},{offset = 0x10, value = 1970561889},{offset = 0x14, value = 1769168755}}},
    {name = "✈️ لافتة طيران للمدينة",                  search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 2002742887},{offset = 0x10, value = 1701277289},{offset = 0x14, value = 1769168740}}},
    {name = "👋 لافتة تحية للمدينة",                   search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1885302375},{offset = 0x10, value = 1601006689},{offset = 0x14, value = 1701147252}}},
    {name = "📺 لافتة معكم على الهواء مباشرة",         search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1415540327},{offset = 0x10, value = 1768120150},{offset = 0x14, value = 1935636852}}},
    {name = "🌟 لافتة رائعة للمدينة",                  search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1834970727},{offset = 0x10, value = 1769239417},{offset = 0x14, value = 1600938339}}},
    {name = "🏠 لافتة منزل مريح",                      search = 1852402547, checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1717530215},{offset = 0x10, value = 1768845941},{offset = 0x14, value = 1701999988}}},
}

-- ═══════════════════════════════════════════════════════════
-- 🪧 تحضير عناوين اللافتات المختارة فقط (بحث مرة واحدة، بدون searchPointer)
-- ═══════════════════════════════════════════════════════════
local function resolveCitySignsAddresses(selectedList)
    if not selectedList or #selectedList == 0 then return nil end

    local searchNumbers = {1852402547, 1735289159}
    local offsets = {0xC, 0x10, 0x14, 0x18}

    gg.setVisible(false); gg.clearResults()
    gg.toast("🔍 البحث الجماعي عن اللافتات...")

    local allAddrs = {}
    for _, num in ipairs(searchNumbers) do
        gg.searchNumber(tostring(num), gg.TYPE_DWORD)
        local r = gg.getResults(gg.getResultsCount())
        for _, v in ipairs(r) do allAddrs[#allAddrs + 1] = v.address end
        gg.clearResults()
    end
    if #allAddrs == 0 then gg.toast("❌ لا نتائج للبحث"); return nil end

    local chk4 = {}
    for i, a in ipairs(allAddrs) do
        chk4[i] = {address = a - 0x4, flags = gg.TYPE_DWORD}
    end
    local v4 = gg.getValues(chk4)
    local valid = {}
    for i, a in ipairs(allAddrs) do
        if v4[i].value == 0 then valid[#valid + 1] = a end
    end
    gg.clearResults()
    if #valid == 0 then gg.toast("❌ لا نتائج تحقق -0x4=0"); return nil end

    local reads = {}
    for _, addr in ipairs(valid) do
        for _, off in ipairs(offsets) do
            reads[#reads + 1] = {address = addr + off, flags = gg.TYPE_DWORD}
        end
    end
    local vals = gg.getValues(reads)

    local addrMap = {}
    for i, addr in ipairs(valid) do
        local base = (i - 1) * #offsets
        local vC   = vals[base + 1].value
        local v10  = vals[base + 2].value
        local v14  = vals[base + 3].value
        local v18  = vals[base + 4].value
        local key = tostring(vC).."_"..tostring(v10).."_"..tostring(v14)
        if not addrMap[key] then addrMap[key] = {} end
        table.insert(addrMap[key], {addr = addr, v18 = v18})
    end

    local output, failedNames = {}, {}
    for _, item in ipairs(selectedList) do
        local k1, k2, k3, disamb
        for _, c in ipairs(item.checks or {}) do
            if     c.offset == 0xC  then k1 = c.value
            elseif c.offset == 0x10 then k2 = c.value
            elseif c.offset == 0x14 then k3 = c.value
            elseif c.offset == 0x18 then disamb = c.value
            end
        end
        local key = tostring(k1 or 0).."_"..tostring(k2 or 0).."_"..tostring(k3 or 0)
        local arr = addrMap[key]
        local found
        if arr and #arr > 0 then
            if disamb then
                for i, e in ipairs(arr) do
                    if e.v18 == disamb then
                        found = e.addr
                        table.remove(arr, i)
                        break
                    end
                end
            else
                found = arr[1].addr
                table.remove(arr, 1)
            end
        end
        if found then
            output[#output + 1] = {name = item.name, address = found}
        else
            failedNames[#failedNames + 1] = item.name
        end
    end

    if #failedNames > 0 then
        gg.toast("⚠️ فشل تحديد " .. #failedNames .. " عنصر")
    end
    if #output > 0 then
        gg.toast("✅ تم تحديد " .. #output .. " لافتة")
    end
    return output
end

-- ═══════════════════════════════════════════════════════════
-- 🪧 تدفق اللافتات: اختيار أولاً ← بحث/تحقق ← تبديل كسول
-- ═══════════════════════════════════════════════════════════
local function runCitySignsFlow()
    local fullList = citySignsList
    if not fullList or #fullList == 0 then
        gg.alert("⚠️ القائمة فارغة", "حسناً"); return
    end

    local selectedList = fullList
    if #fullList > 1 then
        local mode = gg.choice({
            "↩️ رجوع",
            "🔄 تبديل الكل (" .. #fullList .. ")",
            "☑️ اختيار يدوي",
            "❌ إلغاء"
        }, nil, "🪧 تغيير لافتات المدينة")
        if not mode or mode == 1 or mode == 4 then return end

        if mode == 3 then
            local display = {}
            for i, p in ipairs(fullList) do display[i] = p.name end
            local sel = gg.multiChoice(display, nil, "☑️ اختر ما تريد تبديله")
            if not sel then return end
            selectedList = {}
            for i, p in ipairs(fullList) do
                if sel[i] then selectedList[#selectedList+1] = p end
            end
            if #selectedList == 0 then gg.toast("⚠️ لم تختر شيئاً"); return end
        end
    end

    local resolved = resolveCitySignsAddresses(selectedList)
    if not resolved or #resolved == 0 then
        gg.toast("❌ فشل التحضير - تأكد من فتح اللعبة")
        return
    end

    startSequentialReplacement(resolved, false, false)
end

showTrainDecorMenu = function()
    currentMenuFn = showTrainDecorMenu
    local items = {
        "🔍 استبدال زينة بالبحث",
        "⚡ استبدال الزينة مباشر",
        "↩️ رجـــــــــــــــــــــــــــــــــــــــــــــوع"
    }
    local c = gg.choice(items, nil, "🚂 زينة القطار")
    if not c or c == 3 then
        currentMenuFn = showMenuB; return showMenuB()
    end

    if c == 1 then
        -- الخيار الأول: trainDecorationsList (بحث جماعي)
        local resolved = resolveTrainDecorations()
        if resolved and #resolved > 0 then
            startSequentialReplacement(resolved, false)
        else
            gg.toast("❌ فشل التحضير - تأكد من فتح اللعبة")
        end
    elseif c == 2 then
        -- الخيار الثاني: prepareShiftItems مباشر
        local list = prepareShiftItems("1918132078", -0x4, "قطار")
        if list then
            startSequentialReplacement(list, false)
        end
    end
end


-- ═══════════════════════════════════════════════════════════
-- 8) الزينة والبوابات (استخدام نظام Shift)
-- ═══════════════════════════════════════════════════════════
showFenceDecorMenu = function()
    currentMenuFn = showFenceDecorMenu
    local choice = gg.choice({
        "↩️ رجـــــــــــــــــــــــــــــــــوع",
        "🚧 استبـــدال الأســـوار"
    }, nil, "🏰 قائمة البوابات والاسيجة")
    if not choice or choice == 1 then
        currentMenuFn = showCityDecorMenu; return showCityDecorMenu()
    end

    if choice == 2 then
        local fencesList = {
            {name = "🍪 بوابة بسكويت الزنجبيل", values = {1851876116, 1734310244, 6648929, 113, 0, 0}},
            {name = "🥚 سياج عيد الفصح",         values = {1935754520, 1601332596, 1668179302, 101, 0, 0}},
            {name = "🌸 بوابة الزهور",           values = {1634034214, 1601795189, 2003790918, 1734308453, 1936028769, 0}},
            {name = "🏆 بوابات المجد",           values = {1634034214, 1601795189, 1970828620, 1734310258, 1936028769, 0}},
            {name = "🏯 سياج شرقي",              values = {1768440602, 1702061422, 1852139103, 25955, 0, 0}},
            {name = "🎄 سياج عيد الميلاد",       values = {1919435550, 1836348265, 1717531489, 1701015141, 0, 0}},
            {name = "🍓 سياج بسكويت بالفراولة",  values = {1851876118, 1717533028, 1701015141, 0, 0, 0}},
            {name = "🌊 سياج البحر",             values = {1634030364, 1668179270, 1701207909, 6644590, 1634030364, 1668179270}},
            {name = "🪸 سياج مرجاني",            values = {1819558172, 1769238113, 1701207923, 6644590, 0, 0}},
            {name = "🌿 سياج شجيرات",            values = {1684367370, 25959, 920594244, 0, 0, 0}},
            {name = "🏝️ خليج صغير",              values = {1920234264, 1601003877, 1734632808, 101, 0, 0}},
            {name = "🎨 سياج ديكوري",            values = {1634887450, 1702127982, 1852139103, 25955, 0, 0}},
            {name = "🪵 سياج خشبي",              values = {1768453910, 1717527924, 1701015141, 0, 0, 0}},
            {name = "🥇 السياج الذهبي",          values = {2020961304, 1601794677, 1668179302, 101, 0, 0}}
        }
        runGroup({
            list         = fencesList,
            title        = "🚧 استبدال الأسوار",
            askCount     = false,
            stickersMode = false
        })
    end
end

showCityDecorMenu = function()
    currentMenuFn = showCityDecorMenu
    local items = {
        "↩️ رجـــــــــــــــــــــــــــــــــوع",
        "✈️ زينـــة الطائـــرة",
        "🚂 زينـــة القطـــار",
        "🚁 زينـــة الهلوكبـــتر",
        "🏝️ زينـــة الجـــزر",
        "🚢 زينـــة السفـــن",
        "⚓ زينـــة الموانـــي",
        "🚧 زينـــة الســـياج",
        "🪧 تغيير لافتات المدينة",
        "❌ الخـــــــروج"
    }
    local c = gg.choice(items, nil, "🏙️ زينة المدينة")
    if not c then return end
    if c == 1 then currentMenuFn = showMenuB; return showMenuB() end

    if     c == 2 then local list = prepareShiftItems("1765891950", -0x4, "طائرة");    if list then startSequentialReplacement(list, false) end
    elseif c == 3 then showTrainDecorMenu()
    elseif c == 4 then local list = prepareShiftItems("1699241838", -0x4, "هليكوبتر"); if list then startSequentialReplacement(list, false) end
    elseif c == 5 then local list = prepareShiftItems("1866882926", -0x4, "جزيرة");    if list then startSequentialReplacement(list, false) end
    elseif c == 6 then local list = prepareShiftItems("1750294382", -0x4, "سفينة");    if list then startSequentialReplacement(list, false) end
    elseif c == 7 then local list = prepareShiftItems("1632132974", -0x4, "ميناء");    if list then startSequentialReplacement(list, false) end
    elseif c == 8 then showFenceDecorMenu()
     elseif c == 9 then runCitySignsFlow()
    elseif c == 10 then os.exit() end
end

-- ═══════════════════════════════════════════════════════════
-- 🚫 جدول الحظر الاستكشافي (يُستبدل مثل الملصقات)
-- ═══════════════════════════════════════════════════════════
local explorationBanList = {
    {name = "المركبة الصفراء",       values = {1347962144, 1851871839, 909401963, 1935762015, 101, 0}},
    {name = "السحلية الصفراء",       values = {1347962144, 1851871839, 926179179, 1935762015, 101, 0}},
    {name = "الخفاش الاصفر",         values = {1347962144, 1851871839, 942956395, 1935762015, 101, 0}},
    {name = "السيف الاصفر",          values = {1347962144, 1851871839, 959733611, 1935762015, 101, 0}},
    {name = "القطار الاصفر",         values = {1347962144, 1851871839, 808804203, 1935762015, 101, 0}},
    {name = "الدوامه الصفراء",       values = {1347962144, 1851871839, 825581419, 1935762015, 101, 0}},
    {name = "الثور الذهبي",          values = {1347962144, 1851871839, 842358635, 1935762015, 101, 0}},
    {name = "الميراث الغامض",        values = {1347962144, 1851871839, 859135851, 1935762015, 101, 0}},
    {name = "السفينه الصفراء",       values = {1347962144, 1851871839, 875913067, 1935762015, 101, 0}},
    {name = "الصحن الطائر الاصفر",   values = {1347962144, 1851871839, 892690283, 1935762015, 101, 0}},
    {name = "إشارة 56 صفراء",        values = {1347962144, 1851871839, 909467499, 1935762015, 101, 0}},
    {name = "إشارة 57 صفراء",        values = {1347962144, 1851871839, 926244715, 1935762015, 101, 0}},
    {name = "إشارة 58 صفراء",        values = {1347962144, 1851871839, 943021931, 1935762015, 101, 0}},
    {name = "إشارة 59 صفراء",        values = {1347962144, 1851871839, 959799147, 1935762015, 101, 0}},
    {name = "إشارة 60 صفراء",        values = {1347962144, 1851871839, 808869739, 1935762015, 101, 0}},
    {name = "إشارة 61 صفراء",        values = {1347962144, 1851871839, 825646955, 1935762015, 101, 0}},
    {name = "إشارة 62 صفراء",        values = {1347962144, 1851871839, 842424171, 1935762015, 101, 0}},
    {name = "إشارة 63 صفراء",        values = {1347962144, 1851871839, 859201387, 1935762015, 101, 0}},
    {name = "إشارة 64 صفراء",        values = {1347962144, 1851871839, 875978603, 1935762015, 101, 0}},
    {name = "المركبة البنفسج",       values = {1347962146, 1851871839, 909401963, 1634887519, 25710, 0}},
    {name = "السحلية البنفسج",       values = {1347962146, 1851871839, 926179179, 1634887519, 25710, 0}},
    {name = "الخفاش البنفسج",        values = {1347962146, 1851871839, 942956395, 1634887519, 25710, 0}},
    {name = "السيف البنفسج",         values = {1347962146, 1851871839, 959733611, 1634887519, 25710, 0}},
    {name = "القطار البنفسج",        values = {1347962146, 1851871839, 808804203, 1634887519, 25710, 0}},
    {name = "الدوامه البنفسج",       values = {1347962146, 1851871839, 825581419, 1634887519, 25710, 0}},
    {name = "الثور البنفسج",         values = {1347962146, 1851871839, 842358635, 1634887519, 25710, 0}},
    {name = "الميراث البنفسج",       values = {1347962146, 1851871839, 859135851, 1634887519, 25710, 0}},
    {name = "السفينة البنفسج",       values = {1347962146, 1851871839, 875913067, 1634887519, 25710, 0}},
    {name = "الصحن الطائر البنفسج",  values = {1347962146, 1851871839, 892690283, 1634887519, 25710, 0}},
    {name = "إشارة 56 بنفسجية",      values = {1347962146, 1851871839, 909467499, 1634887519, 25710, 0}},
    {name = "إشارة 57 بنفسجية",      values = {1347962146, 1851871839, 926244715, 1634887519, 25710, 0}},
    {name = "إشارة 58 بنفسجية",      values = {1347962146, 1851871839, 943021931, 1634887519, 25710, 0}},
    {name = "إشارة 59 بنفسجية",      values = {1347962146, 1851871839, 959799147, 1634887519, 25710, 0}},
    {name = "إشارة 60 بنفسجية",      values = {1347962146, 1851871839, 808869739, 1634887519, 25710, 0}},
    {name = "إشارة 61 بنفسجية",      values = {1347962146, 1851871839, 825646955, 1634887519, 25710, 0}},
    {name = "إشارة 62 بنفسجية",      values = {1347962146, 1851871839, 842424171, 1634887519, 25710, 0}},
    {name = "إشارة 63 بنفسجية",      values = {1347962146, 1851871839, 859201387, 1634887519, 25710, 0}},
    {name = "إشارة 64 بنفسجية",      values = {1347962146, 1851871839, 875978603, 1634887519, 25710, 0}},
}
local personalIDs = {
    {name = "زهرة بالون الاصفر", values = {1684103706, 811558247, 1633836852, 25971, 0, 0}},
    {name = "زهرة بالون الاحمر", values = {1684103708, 811558247, 1919377204, 6581857, 0, 0}},
    {name = "شارة المدينة الاولى", values = {1684103706, 811558247, 1633836849, 25971, 0, 0}},
    {name = "جرس الذهبي", values = {1684103706, 811558247, 1633836850, 25971, 0, 0}},
    {name = "شارة البلدة الاولى", values = {1684103708, 811558247, 1919377201, 6581857, 0, 0}},
    {name = "جرس الماس", values = {1684103708, 811558247, 1919377202, 6581857, 0, 0}},
    {name = "شارة المدينة التانية", values = {1684103712, 811558247, 846618417, 1935762015, 101, 0}},
    {name = "شارة البلدة التانيه", values = {1684103714, 811558247, 846618417, 1634887519, 25710, 0}},
    {name = "بوصلة صفراء", values = {1684103706, 811558247, 1633836851, 25971, 0, 0}},
    {name = "بوصلة بنفسجي", values = {1684103708, 811558247, 1919377203, 6581857, 0, 0}},
    {name = "شارة الفلفل الاصفر", values = {1684103706, 811558247, 1633836853, 25971, 0, 0}},
    {name = "شارة الفلفل الاحمر", values = {1684103708, 811558247, 1919377205, 6581857, 0, 0}},
    {name = "البطيخ الاحمر", values = {1684103708, 811558247, 1919377206, 6581857, 0, 0}},
    {name = "البطيخ الاخظر", values = {1684103706, 811558247, 1633836854, 25971, 0, 0}},
    {name = "إشارة الحصاد الصفراء", values = {1684103706, 811558247, 1633836855, 25971, 0, 0}},
    {name = "إشارة الحصاد الحمراء",  values = {1684103708, 811558247, 1919377207, 6581857, 0, 0}},
}

showBanDecorMenu = function()
    currentMenuFn = showBanDecorMenu
    local items = {
        "↩️ رجـــــــــــــــــــــــــــــــــوع",
        "🏅 الشـــــــارات",
        "🚫 زخـــارف الحظـــر الاستكشـــافية",
        "🔙 رجـــــــــــــــــــــــــــــــــوع"
    }
    local c = gg.choice(items, nil, "🚫 الزينة التي تسبب حظر")
    if not c then return end
    if c == 1 or c == 4 then currentMenuFn = showMenuB; return showMenuB() end

    if c == 2 then
        runGroup({
            list         = personalIDs,
            title        = "🏅 الشارات",
            askCount     = false,
            stickersMode = false
        })
    elseif c == 3 then
        runGroup({
            list         = explorationBanList,
            title        = "🚫 زخارف الحظر الاستكشافية",
            askCount     = false,
            stickersMode = false
        })
    end
end

-- ═══════════════════════════════════════════════════════════
-- 9) البحث الذكي القديم (للبناء)
-- ═══════════════════════════════════════════════════════════
local function searchAndReplace(config)
    -- 🆕 السؤال عن نوع الصندوق قبل كل استبدال
    local boxType = askBoxType()
    if not boxType then gg.toast("❌ تم الإلغاء"); return false end
    if savedData.boxType ~= boxType then
        savedData.isUpdated = false
    end
    savedData.boxType = boxType

    gg.setVisible(false); monitoring = false; gg.clearResults()
    gg.toast("🔍 جاري البحث عن " .. config.name .. "...")
    gg.searchNumber(config.searchNumber or "1113542739", gg.TYPE_DWORD)
    local results = gg.getResults(gg.getResultsCount())
    if #results == 0 then gg.toast("❌ لم يتم العثور على نتائج"); return false end
    local nChecks = #config.checks
    local checks = {}
    for _, v in ipairs(results) do
        for _, chk in ipairs(config.checks) do checks[#checks + 1] = {address = v.address + chk.offset, flags = gg.TYPE_DWORD} end
    end
    local vals = gg.getValues(checks)
    local foundAddr = nil
    for i, v in ipairs(results) do
        local allMatch = true
        for j, chk in ipairs(config.checks) do
            if vals[(i - 1) * nChecks + j].value ~= chk.value then allMatch = false; break end
        end
        if allMatch then foundAddr = v.address; break end
    end
    gg.clearResults()
    if not foundAddr then gg.toast("❌ لا توجد نتيجة تحقق الشروط"); return false end
    gg.loadResults({{address = foundAddr, flags = gg.TYPE_QWORD}})
    gg.searchPointer(0)
    local ptrs = gg.getResults(10); gg.clearResults()
    if #ptrs == 0 then gg.toast("❌ لم يتم العثور على مؤشر"); return false end
    local ptr = ptrs[1].address
    local src = gg.getValues({
        {address = ptr - 0x10, flags = gg.TYPE_DWORD},{address = ptr - 0xC, flags = gg.TYPE_DWORD},
        {address = ptr - 0x8,  flags = gg.TYPE_DWORD},{address = ptr - 0x4, flags = gg.TYPE_DWORD},
        {address = ptr,        flags = gg.TYPE_DWORD},{address = ptr + 0x4, flags = gg.TYPE_DWORD}
    })
    local itemValues = {src[1].value, src[2].value, src[3].value, src[4].value, src[5].value, src[6].value}
    if not savedData.isUpdated or #savedData.replaceAddresses < 6 then
        if not updateReplacementValues() then gg.toast("❌ فشل تحديث القيم"); return false end
    end
    local mods = {}
    for i = 1, 6 do mods[i] = {address = savedData.replaceAddresses[i], flags = gg.TYPE_DWORD, value = itemValues[i]} end
    gg.setValues(mods)
    gg.setValues({
        {address = savedData.boxAddress + 0x1D8, flags = gg.TYPE_DWORD, value = 0},
        {address = savedData.boxAddress + 0x1DC, flags = gg.TYPE_DWORD, value = config.productValue},
        {address = savedData.boxAddress + 0x1BC, flags = gg.TYPE_DWORD, value = 2}
    })
    gg.toast("✅ تم " .. config.name .. " - بانتظار استلام الهدية...")
    for _ = 1, 1200 do
        if getMonitor2() == 1 then
            local answer = gg.alert("🎁 هل استلمت الهدية؟", "نعم", "أعد الكتابة")
            if answer == 1 then gg.toast("🎉 تم بنجاح")
            else gg.setValues({{address = savedData.boxAddress + 0x1BC, flags = gg.TYPE_DWORD, value = 2}}); gg.toast("🔄 تم إعادة الإشارة") end
            return true
        end
        gg.sleep(100)
    end
    return false
end

-- ═══════════════════════════════════════════════════════════
-- 10) جداول العمليات
-- ═══════════════════════════════════════════════════════════
local buildOperations = {
    {name = "رفع الشونة", icon = "🏗️", searchNumber = "1113542739", checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1130719073},{offset = 0x10, value = 1667330145}}, productValue = 50000},
    {name = "تصفير وقت البناء", icon = "⏱️", searchNumber = "1113542739", checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1114658148},{offset = 0x10, value = 1684826485}}, productValue = 100}
}

local planeDecorOps = {
    {name = "طائرة Township", icon = "✈️", searchNumber = "1852402515", checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1769430885},{offset = 0x10, value = 1702323308}}, productValue = 1},
    {name = "مهبط Township", icon = "✈️", searchNumber = "1852402515", checks = {{offset = -0x4, value = 0},{offset = 0xC, value = 1818851167},{offset = 0x10, value = 1936029540}}, productValue = 1}
}

-- ═══════════════════════════════════════════════════════════
-- 11) حدث الثروة
-- ═══════════════════════════════════════════════════════════
local function setWealthEvent(state)
    gg.clearResults(); gg.setVisible(false); gg.searchNumber("86400", gg.TYPE_DWORD)
    local results = gg.getResults(gg.getResultsCount())
    if #results == 0 then gg.toast("❌ لا نتائج"); return end
    local checks = {}
    for i, r in ipairs(results) do
        checks[#checks+1] = {address = r.address - 0x20, flags = gg.TYPE_DWORD}
        checks[#checks+1] = {address = r.address - 0x24, flags = gg.TYPE_DWORD}
    end
    local values = gg.getValues(checks)
    for i in ipairs(results) do
        if values[(i-1)*2+1].value == 100 and values[(i-1)*2+2].value == 290 then
            gg.setValues({{address = results[i].address - 0x18, flags = gg.TYPE_DWORD, value = state}})
            gg.clearResults(); gg.toast(state == 1500 and "✅ تم فتح حدث الثروة" or "✅ تم إخفاء حدث الثروة"); return
        end
    end
    gg.toast("❌ لم يتم العثور على النمط")
end

-- ═══════════════════════════════════════════════════════════
-- 12) الهلوكبتر
-- ═══════════════════════════════════════════════════════════
function Sefyj()
    gg.alert("⚠️ ادخل إلى الهلوكبتر أولاً ثم عد.")
    local choice = gg.choice({
        "🏙️ رفـــع المدينـــة تلقائيـــاً",
        "🎁 رفـــع أدوات الأحـــداث",
        "⭐ رفـــع المستـــوى الى 167 ",
        "🔹 رفـــع بسيـــط الى 19 لتفادي حظر السباق ",
        "🔸 المستـــوى إلـــى 80",
        "💵 زيـــادة الكـــاش (1000000)",
        "✍️ الخيـــارات اليدويـــة",
        "❌ خـــــــروج"
    }, nil, "⚙️ اختر العملية:")
    if not choice or choice == 8 then return end
    local P = {}
    if choice == 1 then P = {goldCoins=600000, banknotes=1000000, levelUp=90000000, wealthPoints=0, wealth33Points=0}
    elseif choice == 2 then P = {goldCoins=0, banknotes=0, levelUp=0, wealthPoints=999999, wealth33Points=999999}
    elseif choice == 3 then P = {goldCoins=0, banknotes=0, levelUp=90000000, wealthPoints=0, wealth33Points=0}
    elseif choice == 4 then P = {levelUp=400}
    elseif choice == 5 then P = {levelUp=900000}
    elseif choice == 6 then P = {banknotes=1000000}
    elseif choice == 7 then
        local inputs = gg.prompt({"💰 الذهب","💵 الكاش","⭐ المستوىات ","✨ ثروة","🌸 طنين"}, {"","","","",""}, {"number","number","number","number","number"})
        if not inputs then return end
        local keys = {"goldCoins","banknotes","levelUp","wealthPoints","wealth33Points"}
        for i = 1, 5 do local num = tonumber(inputs[i] or 0); if num then P[keys[i]] = num end end
    end
    if not next(P) then return end
    gg.clearResults(); gg.searchNumber("1800", gg.TYPE_DWORD)
    local results = gg.getResults(gg.getResultsCount())
    if #results == 0 then return end
    local addrs = {}; for i, r in ipairs(results) do addrs[i] = {address = r.address - 0x8, flags = gg.TYPE_DWORD} end
    gg.loadResults(addrs); local base
    for i, v in ipairs(gg.getResults(#addrs)) do if v.value == -8 then base = results[i].address; break end end
    if not base then return end
    gg.loadResults({{address = base - 0x8, flags = gg.TYPE_QWORD}}); gg.searchPointer(0)
    local pointers = gg.getResults(50)
    local offs = {goldCoins=0x28, banknotes=0x30, levelUp=0x48, wealth33Points=0x80, wealthPoints=0x98}
    local count = 0
    for _, ptr in ipairs(pointers) do
        local mods = {}
        for k, off in pairs(offs) do
            if P[k] then mods[#mods+1] = {address=ptr.address+off, flags=gg.TYPE_DWORD, value=0}; mods[#mods+1] = {address=ptr.address+off+4, flags=gg.TYPE_DWORD, value=P[k]} end
        end
        if #mods > 0 and gg.setValues(mods) then count = count + 1 end
    end
    gg.clearResults(); gg.toast(count > 0 and "✅ تم تعديل "..count.." عنوان 🎉" or "⚠️ فشل التعديل")
end

-- ═══════════════════════════════════════════════════════════
-- 13) القمح والتصريح
-- ═══════════════════════════════════════════════════════════
function goldenChards()
    -- مربع إدخال الرقم المطلوب
    local input = gg.prompt(
        {"أدخل الرقم الذي تريد رفعه من خلال القمح : 🌾"},
        {"9999999"},
        {"number"}
    )
    if input == nil then
        gg.toast("❌ تم الإلغاء")
        return
    end
    local targetValue = tonumber(input[1])
    if not targetValue or targetValue < 0 then
        gg.toast("⚠️ رقم غير صالح")
        return
    end

    gg.clearResults()
    gg.searchNumber("1701147414", gg.TYPE_DWORD)
    local results = gg.getResults(gg.getResultsCount())
    if #results == 0 then
        gg.toast("❌ لم يتم العثور على نتائج")
        return
    end

    local checks = {}
    for i, r in ipairs(results) do
        checks[i] = {address = r.address + 0x80, flags = gg.TYPE_FLOAT}
    end

    local values = gg.getValues(checks)
    local edits, validCount = {}, 0

    for i, r in ipairs(results) do
        if values[i] and math.abs(values[i].value - 120) < 0.5 then
            validCount = validCount + 1
            edits[#edits + 1] = {address = r.address + 0x80, flags = gg.TYPE_FLOAT, value = 0}
            edits[#edits + 1] = {address = r.address + 0x90, flags = gg.TYPE_DWORD, value = 0}
            edits[#edits + 1] = {address = r.address + 0x94, flags = gg.TYPE_DWORD, value = targetValue}
        end
    end

    if #edits > 0 then gg.setValues(edits) end
    gg.clearResults()
    gg.toast("✅ تم تعديل " .. validCount .. " عنوان إلى " .. targetValue .. " 🌾")
end

function goldenCyihards()
    gg.clearResults(); gg.searchNumber("1937011470;6447364::481", gg.TYPE_DWORD); gg.refineNumber("6447364", gg.TYPE_DWORD)
    local results = gg.getResults(550); if #results == 0 then return end
    local valid = {}
    for _, v in ipairs(results) do
        local check = gg.getValues({{address = v.address - 0x5C, flags = gg.TYPE_DWORD},{address = v.address - 0x68, flags = gg.TYPE_DWORD}})
        if check[1].value == check[2].value then
            valid[#valid+1] = v.address
            gg.setValues({{address = v.address + 0x78, value = 1, flags = gg.TYPE_DWORD},{address = v.address + 0x6C, value = 1000, flags = gg.TYPE_DWORD},{address = v.address + 0x68, value = 0, flags = gg.TYPE_DWORD}})
        end
    end
    gg.toast(#valid > 0 and ("🎉 تم تفعيل التصريح") or "❌ لم يتم العثور على قيم صالحه تاكد")
end



-- ─────── 1) تفعيل إرسال الكروت (u) ───────
function u()
    gg.clearResults(); gg.searchNumber("-715855975", gg.TYPE_DWORD)
    local results = gg.getResults(1); local freezeList, success = {}, false
    if #results > 0 then
        gg.loadResults({{address = results[1].address - 0x4, flags = gg.TYPE_QWORD}})
        gg.searchPointer(0)
        for _, r in ipairs(gg.getResults(5)) do
            if gg.getValues({{address = r.address + 0x78, flags = gg.TYPE_DWORD}})[1].value == 86400 then
                local mods = {}
                for _, off in ipairs({0x98,0x9C,0xA0,0xA4,0xA8,0xAC}) do
                    mods[#mods+1] = {address=r.address+off, flags=gg.TYPE_DWORD, value=0, freeze=true}
                end
                gg.setValues(mods); for _, m in ipairs(mods) do freezeList[#freezeList+1] = m end
                success = true; break
            end
        end
    end
    if #freezeList > 0 then gg.addListItems(freezeList) end
    gg.clearResults(); gg.searchNumber("-839312791", gg.TYPE_DWORD)
    local r2 = gg.getResults(4)
    if #r2 > 0 then
        local mods = {}
        for _, v in ipairs(r2) do
            local addr = v.address + 0x10
            if gg.getValues({{address=addr, flags=gg.TYPE_DWORD}})[1].value == 1684828007 then
                mods[#mods+1] = {address=addr, flags=gg.TYPE_DWORD, value=0}
            end
        end
        if #mods > 0 then gg.setValues(mods); success = true end
    end
    gg.clearResults(); gg.toast(success and "✅ تم تفعيل إرسال الكروت 🎴" or "❌ لم يتم أي تعديل")
end

function goldenCCards()
    gg.clearResults()
    gg.toast("🔍 جاري البحث عن البطاقات...")
    
    gg.searchNumber("1918984974~1918984976;1~12;1~12;1~12::33", gg.TYPE_DWORD)
    gg.refineNumber("1~12", gg.TYPE_DWORD)
    
    local results = gg.getResults(gg.getResultsCount())
    if #results == 0 then
        gg.toast("❌ لم يتم العثور على نتائج")
        return false
    end

    local checkAddresses = {}
    for i, v in ipairs(results) do
        checkAddresses[i] = {
            address = v.address - 0x1C,
            flags = gg.TYPE_DWORD
        }
    end
    
    gg.toast("🔎 انني اعمل بجهد انتظرني حبيبي")
    
    local checkResults = gg.getValues(checkAddresses)
    
    local validAddresses = {}
    local requiredValues = {1918984974, 1918984976}
    local requiredMap = {}
    for _, val in ipairs(requiredValues) do
        requiredMap[val] = true
    end
    
    for i, result in ipairs(checkResults) do
        if requiredMap[result.value] then
            table.insert(validAddresses, results[i].address)
        end
    end
    
    if #validAddresses == 0 then
        gg.toast("❌ لم يتم العثور على نتائج مطابقة للشروط")
        return false
    end
    
    local inputs = gg.prompt({
        "💰 أدخل القيمة الجديدة للبطاقات",
        "📊 عدد البطاقات المتاحة: " .. #validAddresses
    }, {0}, {"number"})
    
    if inputs == nil then
        gg.toast("✅ تم إلغاء العملية")
        return false
    end
    
    local newValue = tonumber(inputs[1])
    
    if newValue == nil or newValue < 0 then
        gg.toast("❌ قيمة غير صحيحة")
        return false
    end
    
    local modifiedResults = {}
    for i, addr in ipairs(validAddresses) do
        modifiedResults[i] = {
            address = addr,
            flags = gg.TYPE_DWORD,
            value = newValue
        }
    end
    
    if gg.setValues(modifiedResults) then
        gg.clearResults()
        gg.toast("🎉 تم تزويد البطاقات بنجاح ")
    else
        gg.toast("⚠️ فشل في تعديل بعض القيم")
        return false
    end
    
    return true
end


function freezeCards1()
    if gg.alert("⚠️ تنبيه\n\nيُستحسن تشغيل (➕ تزويد الكروت) أولاً لضمان سلامة القيم.\n\nهل تريد المتابعة؟", "✅ نعم", "❌ إلغاء") ~= 1 then return gg.toast("✅ تم الإلغاء") end

    gg.clearResults(); gg.setVisible(false)
    gg.toast("🔍 جاري الفحص الشامل...")
    gg.searchNumber(CARD_V1_MIN.."~"..CARD_V1_MAX, gg.TYPE_DWORD)
    local res = gg.getResults(gg.getResultsCount())
    if #res == 0 then gg.clearResults(); gg.setVisible(true); return gg.toast("❌ لا نتائج") end

    local chk = {}
    for _, r in ipairs(res) do
        chk[#chk+1] = {address = r.address + 0x4,  flags = gg.TYPE_DWORD}
        chk[#chk+1] = {address = r.address + 0x18, flags = gg.TYPE_DWORD}
        chk[#chk+1] = {address = r.address + 0x1C, flags = gg.TYPE_DWORD}
        chk[#chk+1] = {address = r.address - 0x28, flags = gg.TYPE_DWORD}
        chk[#chk+1] = {address = r.address + 0x28, flags = gg.TYPE_DWORD}
    end
    local vals = gg.getValues(chk)

    local ownedCounts, empty = {}, {}
    for i, r in ipairs(res) do
        local b   = (i-1)*5
        local v1    = r.value
        local v2    = vals[b+1].value
        local v18   = vals[b+2].value
        local v1C   = vals[b+3].value
        local v_m28 = vals[b+4].value
        local v_p28 = vals[b+5].value

        local isNeighborValid = (v_m28 == 1918984974 or v_m28 == 1918984976 or v_p28 == 1918984974 or v_p28 == 1918984976)
        local key = tostring(v1).."_"..tostring(v2)

        if CardIndexV1V2[key] and isNeighborValid then
            if v1C >= 0 and v1C <= 0 then
                ownedCounts[key] = (ownedCounts[key] or 0) + 1
            end
        end

        local isEmpty = (v18 == 1 or v18 < 0) and (v1C == 1 or v1C < 0) and isNeighborValid
        if isEmpty then
            empty[#empty+1] = r.address
        end
    end
    gg.clearResults(); gg.setVisible(true)

    -- حساب الناقص
    local missing = {}
    local processedCounts = {}
    for i, c in ipairs(cardsList) do
        local key = tostring(c[1]).."_"..tostring(c[2])
        processedCounts[key] = (processedCounts[key] or 0) + 1
        if not ownedCounts[key] or processedCounts[key] > ownedCounts[key] then
            missing[#missing+1] = {idx = i, card = c}
        end
    end

    local existingCount = 150 - #missing
    local toFill = math.min(#missing, #empty)

    -- ✅ التقرير الذي يوضح للمستخدم ما تم اكتشافه
    local report = "📊 تقرير الفحص الدقيق:\n\n"
    report = report .. "✅ الكروت المملوكة: " .. existingCount .. " / 150\n"
    report = report .. "⚠️ الكروت الناقصة: " .. #missing .. "\n"
    report = report .. "🕳️ الخانات الفارغة المكتشفة: " .. #empty .. "\n\n"
    
    if #missing == 0 then
        return gg.alert(report .. "🎉 ممتاز! جميع الكروت موجودة بالفعل.", "حسناً")
    end

    if toFill == 0 then
        return gg.alert(report .. "❌ لا توجد خانات فارغة كافية لإضافة الناقص.", "حسناً")
    end

    -- ✅ سؤال المستخدم: هل تريد الإضافة التلقائية أم لا؟
    report = report .. "🔧 هل تريد إضافة " .. toFill .. " كرت ناقص تلقائياً في الخانات الفارغة؟"
    
    if gg.alert(report, "✅ نعم، إضافة تلقائية", "❌ إلغاء") ~= 1 then 
        return gg.toast("✅ تم الإلغاء") 
    end

    -- (اختياري) يمكنك هنا إضافة كود يطبع أرقام الكروت الناقصة في المربع الحوار
    local missingIds = ""
    for i = 1, math.min(#missing, 10) do
        missingIds = missingIds .. missing[i].idx .. "، "
    end
    if #missing > 10 then missingIds = missingIds .. "..." end
    gg.toast("جاري إضافة: " .. missingIds)

    local list = {}
    for i = 1, toFill do
        local card = missing[i].card
        local base = empty[i]
        for k = 1, 6 do
            list[#list+1] = {address = base + (k-1)*4, flags = gg.TYPE_DWORD, value = card[k], freeze = true}
        end
    end

    gg.setValues(list); gg.addListItems(list)
    gg.toast("🎉 تم إضافة وتجميد " .. toFill .. " كرت ناقص")
end

-- ─────── 3) تجميد الكروت (freezeCards) ───────
function freezeCards()
    local CARD_H2 = 1918984974 -- card_01 .. card_99
    local CARD_H3 = 1918984976 -- card_100 .. card_160
    local CARD_RANGE = CARD_H2 .. "~" .. CARD_H3
    local OFF_CNT, OFF_A, OFF_B = 24, 28, 32
    local VAL_MAX = 150000

    local choice = gg.choice({
        "🃏 150 كـــارت",
        "🃏 160 كـــارت"
    }, nil, "🃏 كم عدد الكروت في مجموعتك؟")
    if not choice then return end
    local CARD_MAX = (choice == 1) and 150 or 160

    local function getCardCode(n)
        local s = string.format("card_%02d", n)
        local bytes = {#s * 2}
        for i = 1, #s do bytes[#bytes + 1] = s:byte(i) end
        for i = #bytes + 1, 24 do bytes[i] = 0 end
        local code = {}
        for i = 0, 5 do
            local b = i * 4
            code[i + 1] = bytes[b + 1]
                        + bytes[b + 2] * 256
                        + bytes[b + 3] * 65536
                        + bytes[b + 4] * 16777216
        end
        return code
    end

    local cardLookup = {}
    for n = 1, CARD_MAX do
        local c = getCardCode(n)
        if n < 100 then
            cardLookup[c[1] .. ":" .. c[2]] = n
        else
            cardLookup[c[1] .. ":" .. c[2] .. ":" .. (c[3] % 256)] = n
        end
    end

    gg.clearResults()
    gg.searchNumber(CARD_RANGE .. ";1~10000::33", gg.TYPE_DWORD)
    gg.refineNumber(CARD_RANGE, gg.TYPE_DWORD)

    local count = gg.getResultCount()
    if count == 0 then
        gg.alert(
            "⚠️ لم يتم العثور ⚠️\n\n" ..
            "تأكد من وجود كارت في مجموعتك\n" ..
            "له نسخة واحدة فقط وليس أكثر.\n\n" ..
            "🔄 ثم أعد المحاولة.\n\n" ..
            "📌 إذا لم تنجح الطريقة:\n" ..
            "اضبط نطاقات الذاكرة المناسبة لجهازك.",
            "حسناً")
        return
    end

    local results = gg.getResults(count)

    local OFFSETS = {0, 4, 8, OFF_CNT, OFF_A, OFF_B}
    local N = #OFFSETS
    local reads = {}
    for _, r in ipairs(results) do
        for _, off in ipairs(OFFSETS) do
            reads[#reads + 1] = {address = r.address + off, flags = gg.TYPE_DWORD}
        end
    end
    local vals = gg.getValues(reads)

    local function isRealEntry(cnt, a, c)
        return a >= 1 and a <= VAL_MAX and c >= 1 and c <= VAL_MAX
    end

    local found, foundAny = {}, false
    local writeTo, fallback
    for i = 1, count do
        local b = (i - 1) * N
        local v1  = vals[b + 1].value
        local v2  = vals[b + 2].value
        local v3  = vals[b + 3].value
        local cnt = vals[b + 4].value
        local a   = vals[b + 5].value
        local c   = vals[b + 6].value

        local key
        if v1 == CARD_H2 then
            key = v1 .. ":" .. v2
        elseif v1 == CARD_H3 then
            key = v1 .. ":" .. v2 .. ":" .. (v3 % 256)
        end
        local n = key and cardLookup[key]

        if n and isRealEntry(cnt, a, c) then
            found[n] = true
            foundAny = true

            local item = {address = results[i].address, flags = results[i].flags}
            if not writeTo and v1 == CARD_H2 and a == 1 and c == 1 then
                writeTo = item
            end
            if not fallback then
                fallback = item
            end
        end
    end

    if not foundAny then
        gg.alert(
            "⚠️ لم يتم العثور على كروت صالحة ⚠️\n\n" ..
            "🔄 أعد المحاولة، أو اضبط نطاقات الذاكرة المناسبة لجهازك.",
            "حسناً")
        return
    end

    writeTo = writeTo or fallback

    local missingList = {}
    for n = 1, CARD_MAX do
        if not found[n] then missingList[#missingList + 1] = n end
    end

    if #missingList == 0 then
        gg.alert("🎉 جميع الكروت موجودة في مجموعتك!\nلا يوجد شيء للتجميد.", "حسناً")
        return
    end

    if not writeTo then
        gg.alert(
            "⚠️ لم يتم العثور ⚠️\n\n" ..
            "🔄 أعد المحاولة، أو اضبط نطاقات الذاكرة المناسبة لجهازك.",
            "حسناً")
        return
    end

    local missingToFreeze = missingList[1]
    local code = getCardCode(missingToFreeze)

    local editTable = {}
    for i = 1, 6 do
        editTable[i] = {
            address = writeTo.address + (i - 1) * 4,
            flags = writeTo.flags,
            value = code[i]
        }
    end

    gg.setValues(editTable)
    gg.addListItems(editTable)

    local shown = {}
    for i = 1, math.min(#missingList, 40) do
        shown[i] = missingList[i]
    end
    local missingText = table.concat(shown, "، ") .. (#missingList > 40 and " ..." or "")

    gg.alert(
        "📋 الكروت المفقودة: " .. missingText .. "\n\n" ..
        "❄️ تم تجميد الكارت رقم: " .. missingToFreeze .. "\n\n" ..
        "━━━━━━━━━━━━━━━\n" ..
        "⚠️ كل ما عليك زيادة الكارت الناقص\n" ..
        "من التذكرة 🎫 أو من صندوق النجوم ⭐",
        "حسناً")
end

-- ─────── 4) إرسال لشخص ليس صديقك (sjdk) ───────
function sjdk()
    gg.clearResults(); gg.setVisible(false); gg.searchNumber("-2019434980", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
    local results = gg.getResults(gg.getResultsCount())
    if #results == 0 then gg.toast("❌ لم يتم العثور على نتائج"); return false end
    local foundAddress = nil
    for _, v in ipairs(results) do
        if gg.getValues({{address = v.address - 0x28, flags = gg.TYPE_DWORD}})[1].value == 983044 then
            foundAddress = v.address; break
        end
    end
    if not foundAddress then gg.toast("❌ لم يتم العثور"); gg.clearResults(); return false end
    local baseAddr = foundAddress + 0x268; local readAddresses = {}
    for i = 1, 6 do table.insert(readAddresses, {address = baseAddr + (i - 1) * 4, flags = gg.TYPE_DWORD}) end
    local copiedValues = gg.getValues(readAddresses)
    local pasteAddr = foundAddress + 0x170; local writeMods = {}
    for i = 1, 6 do
        table.insert(writeMods, {address = pasteAddr + (i - 1) * 4, flags = gg.TYPE_DWORD, value = copiedValues[i].value})
    end
    gg.setValues(writeMods); gg.clearResults()
    gg.toast("✅ تم تجهيز الإرسال للشخص غير الصديق")
    return true
end

showTrainDecorMenu = function()
    currentMenuFn = showTrainDecorMenu
    local items = {
        "🔍 استبـــدال زينـــة بالبحـــث",
        "⚡ استبـــدال الزينـــة مباشـــر",
        "↩️ رجـــــــــــــــــــــــــــــــــوع"
    }
    local c = gg.choice(items, nil, "🚂 زينة القطار")
    if not c or c == 3 then
        currentMenuFn = showMenuB; return showMenuB()
    end

    if c == 1 then
        local resolved = resolveTrainDecorations()
        if resolved and #resolved > 0 then
            startSequentialReplacement(resolved, false)
        else
            gg.toast("❌ فشل التحضير - تأكد من فتح اللعبة")
        end
    elseif c == 2 then
        local list = prepareShiftItems("1918132078", -0x4, "قطار")
        if list then
            startSequentialReplacement(list, false)
        end
    end
end


-- ═══════════════════════════════════════════════════════════
-- 🎴 قائمة مغلفات الصور (تستخدم دوال التبديل runGroup)
-- ═══════════════════════════════════════════════════════════
showCardPacksMenu = function()
    currentMenuFn = showCardPacksMenu
    local c = gg.choice({
        "↩️ رجـــــــوع",
        "📸 مغلفـــات الصـــور (بـــرقم معيـــن)",
        "🖼️ مغلفـــات الصـــور (48 ثابـــت)",
        "❌ إلغـــاء"
    }, nil, "🎴 مغلفات الصور")

    if not c or c == 1 or c == 4 then
        currentMenuFn = showCardsSectionMenu
        return showCardsSectionMenu()
    end

    local item = cardPacksItems[c - 1]
    if not item then return end

    -- ⚡ بناءً على قيمة count في cardPacksItems:
    --    count = true  → يسأل المستخدم عن العدد
    --    count = 48    → يستخدم 48 ثابت
    runGroup({
        list         = {{ name = item.name, values = item.values }},
        title        = item.name,
        askCount     = (item.count == true),
        fixedCount   = (type(item.count) == "number") and item.count or nil,
        stickersMode = true   -- ✅ يعرض إشعار "أغلق اللعبة وأعد فتحها"
    })
end

showCardsSectionMenu = function()
    currentMenuFn = showCardsSectionMenu
    local c = gg.choice({
        "📤 إرســـال الكـــروت",
        "➕ تزويـــد الكـــروت",
        "🎴 مغلفـــات الكـــروت",
        "🧊 تجميـــد الكـــروت",
        "🧊 الإفـــراج عـــن الكـــروت",
        "👥 إرســـال لغـــير صديقـــك",
        "⭐ تزويـــد النجـــوم",
        "↩️ رجـــــــــــــــــــــــــــــــــوع"
    }, nil, "💳 قسم الكروت")
    if not c then return end
    if c == 8 then
        currentMenuFn = showMainMenu
        return showMainMenu()
    end

    -- ✅ ربط مباشر بالدوال الحقيقية (بدلاً من جدول fns غير الموجود)
    if     c == 1 then u()                    -- إرسال الكروت
    elseif c == 2 then goldenCCards()         -- تزويد الكروت
    elseif c == 3 then showCardPacksMenu()    -- 🎴 مغلفات الصور (المُصلحة)
    elseif c == 4 then freezeCards()          -- تجميد الكروت
    elseif c == 5 then freezeCards1()         -- الإفراج عن الكروت (فحص + إعادة ملء الفراغات)
    elseif c == 6 then sjdk()                 -- إرسال لغير صديقك
    elseif c == 7 then gg.toast("⚠️ هذه الميزة غير متوفرة حالياً")
    end
end
    

-- ═══════════════════════════════════════════════════════════
-- 15) محرك الطائرة والقطار الكامل
-- ═══════════════════════════════════════════════════════════
local pointer1, pointer2, pointerTrains = nil, nil, nil
local monitorAddress1, monitorAddress2, monitorEditAddress1, monitorEditAddress2 = nil, nil, nil, nil
local lastMonitorValue1, lastMonitorValue2 = 0, 0
local monitoringEnabled, productMonitoringEnabled = false, false
local frozenAddresses = {}
local savedTrainAddresses, savedPointer1Addresses = {}, {}

-- 🆕 المنتجات
local PRODUCT_WHEAT = {name = "قمح", v1 = 1701345034, v2 = 29793}
local PRODUCT_CROWN = {name = "تاج", v1 = 1634296844, v2 = 7169380}
local selectedProduct = PRODUCT_WHEAT
local productCount    = 1

-- 🛡️ قراءة آمنة: تقرأ ثم تمسح فوراً (لا تترك أثر قابل للسرقة)
local function safeGetResults(n)
    local r = gg.getResults(n or gg.getResultsCount())
    gg.clearResults()
    return r
end
local function safeGetValues(list)
    local v = gg.getValues(list)
    gg.clearResults()
    return v
end

local function askProductChoice()
    local c = gg.choice({
        "🌾 قمـــح (أي رقـــم)",
        "👑 تـــاج (1-40)",
        "↩️ إلغـــاء"
    }, nil, "🌾 اختر نوع المنتج\n\n📌 يُحفظ ويُستخدم تلقائياً")
    if not c or c == 3 then return false end

    if c == 1 then
        selectedProduct = PRODUCT_WHEAT
        local inp = gg.prompt({"🌾 عدد القمح (أي رقم موجب):"}, {"1"}, {"number"})
        if not inp then return false end
        local n = tonumber(inp[1])
        if not n or n <= 0 then gg.toast("🙂 رقم غير مناسب"); return false end
        productCount = math.floor(n)
    else
        selectedProduct = PRODUCT_CROWN
        local inp = gg.prompt({"👑 عدد التاج (1-40):"}, {"1"}, {"number"})
        if not inp then return false end
        local n = tonumber(inp[1])
        if not n or n <= 0 then gg.toast("🙂 رقم غير مناسب"); return false end
        if n > 40 then n = 40; gg.toast("👍 تم الضبط على 40") end
        productCount = math.floor(n)
    end

    gg.alert("✅ تم الحفظ\n\n📦 " .. selectedProduct.name .. "\n🔢 × " .. productCount, "حسناً")
    return true
end

-- ملفات الحفظ
local pointersFile         = gg.getFile() .. ".pointers"
local monitoringFile       = gg.getFile() .. ".monitoring"
local trainsPointerFile    = gg.getFile() .. ".trains_pointer"
local trainAddressesFile   = gg.getFile() .. ".train_addresses"
local pointer1AddressesFile= gg.getFile() .. ".pointer1_addresses"

local function saveLinesToFile(fp, list)
    local f = io.open(fp, "w"); if f then for _, v in ipairs(list) do f:write(v .. "\n") end; f:close(); return true end; return false
end
local function loadLinesFromFile(fp)
    local list = {}; local f = io.open(fp, "r")
    if f then local c = f:read("*a"); f:close(); for line in c:gmatch("[^\r\n]+") do local v = tonumber(line); if v then table.insert(list, v) end end end
    return list
end
local function saveTrainAddresses()  saveLinesToFile(trainAddressesFile, savedTrainAddresses) end
local function loadTrainAddresses()  savedTrainAddresses = loadLinesFromFile(trainAddressesFile) end
local function savePointer1Addresses() saveLinesToFile(pointer1AddressesFile, savedPointer1Addresses) end
local function loadPointer1Addresses() savedPointer1Addresses = loadLinesFromFile(pointer1AddressesFile) end
local function saveTrainsPointer()
    local f = io.open(trainsPointerFile, "w"); if f then f:write("pointerTrains=" .. (pointerTrains or "nil") .. "\n"); f:close() end
end
local function loadTrainsPointer()
    local f = io.open(trainsPointerFile, "r")
    if f then local c = f:read("*a"); f:close(); local n, v = c:match("(.+)=(.+)"); if n == "pointerTrains" and v ~= "nil" then pointerTrains = v; return true end end
    return false
end
local function savePointers()
    local f = io.open(pointersFile, "w"); if f then f:write("pointer1=" .. (pointer1 or "nil") .. "\n"); f:write("pointer2=" .. (pointer2 or "nil") .. "\n"); f:close() end
end
local function loadPointers()
    local f = io.open(pointersFile, "r")
    if f then local c = f:read("*a"); f:close(); for line in c:gmatch("[^\r\n]+") do local n, v = line:match("(.+)=(.+)"); if n == "pointer1" and v ~= "nil" then pointer1 = v elseif n == "pointer2" and v ~= "nil" then pointer2 = v end end end
end
local function saveMonitoring()
    local f = io.open(monitoringFile, "w")
    if f then
        f:write("monitorAddress1=" .. (monitorAddress1 or "nil") .. "\n")
        f:write("monitorAddress2=" .. (monitorAddress2 or "nil") .. "\n")
        f:write("monitorEditAddress1=" .. (monitorEditAddress1 or "nil") .. "\n")
        f:write("monitorEditAddress2=" .. (monitorEditAddress2 or "nil") .. "\n")
        f:write("lastMonitorValue1=" .. (lastMonitorValue1 or "nil") .. "\n")
        f:write("lastMonitorValue2=" .. (lastMonitorValue2 or "nil") .. "\n")
        f:close()
    end
end
local function loadMonitoring()
    local f = io.open(monitoringFile, "r")
    if f then
        local c = f:read("*a"); f:close()
        for line in c:gmatch("[^\r\n]+") do
            local n, v = line:match("(.+)=(.+)")
            if     n == "monitorAddress1"     and v ~= "nil" then monitorAddress1 = tonumber(v)
            elseif n == "monitorAddress2"     and v ~= "nil" then monitorAddress2 = tonumber(v)
            elseif n == "monitorEditAddress1" and v ~= "nil" then monitorEditAddress1 = tonumber(v)
            elseif n == "monitorEditAddress2" and v ~= "nil" then monitorEditAddress2 = tonumber(v)
            elseif n == "lastMonitorValue1"   and v ~= "nil" then lastMonitorValue1 = tonumber(v)
            elseif n == "lastMonitorValue2"   and v ~= "nil" then lastMonitorValue2 = tonumber(v) end
        end
    end
end

local function saveTrainAddressesFromPointer(ptr)
    gg.clearResults(); gg.searchNumber(ptr, gg.TYPE_QWORD)
    local r = safeGetResults(9) -- 🔒 مسح فوري
    savedTrainAddresses = {}
    if #r == 0 then return false end
    for _, v in ipairs(r) do table.insert(savedTrainAddresses, v.address) end
    saveTrainAddresses(); return true
end
local function savePointer1AddressesFromSearch()
    if not pointer1 or pointer1 == "" then return false end
    gg.clearResults(); gg.searchNumber(pointer1, gg.TYPE_QWORD)
    local r = safeGetResults(6) -- 🔒 مسح فوري
    savedPointer1Addresses = {}
    if #r == 0 then return false end
    for _, x in ipairs(r) do table.insert(savedPointer1Addresses, x.address) end
    savePointer1Addresses(); return true
end

-- استخراج المؤشرات (صامت + 🔒 مسح فوري بعد كل قراءة)
local function extractPointer1()
    gg.setVisible(false); gg.clearResults(); gg.searchNumber("264", gg.TYPE_DWORD)
    local c = gg.getResultsCount()
    if c == 0 then gg.clearResults(); return false end
    if c > 10000 then gg.clearResults(); return false end
    local r = safeGetResults(c) -- 🔒 مسح فوري

    local chk1 = {}
    for _, x in ipairs(r) do chk1[#chk1+1] = {address = x.address - 0x8, flags = gg.TYPE_DWORD}; chk1[#chk1+1] = {address = x.address + 0x8, flags = gg.TYPE_DWORD} end
    local cv1 = safeGetValues(chk1) -- 🔒
    local valid = {}
    for i, x in ipairs(r) do if cv1[(i-1)*2+1].value == -8 and cv1[(i-1)*2+2].value == 8 then valid[#valid+1] = x.address end end
    if #valid == 0 then return false end
    if #valid > 2 then valid = {valid[1], valid[2]} end

    local secondResults = nil
    for _, addr in ipairs(valid) do
        gg.clearResults(); gg.loadResults({{address = addr - 0x8, flags = gg.TYPE_QWORD}}); gg.searchPointer(0)
        local cnt = gg.getResultsCount()
        if cnt > 0 and cnt < 20 then secondResults = safeGetResults(cnt); break end
        gg.clearResults() -- 🔒 في حال عدم المطابقة
    end
    if not secondResults then return false end

    local chk2 = {}; for _, v in ipairs(secondResults) do chk2[#chk2+1] = {address = v.address + 0x84, flags = gg.TYPE_DWORD} end
    local cv2 = safeGetValues(chk2) -- 🔒
    local correctAddr2 = nil
    for i, v in ipairs(secondResults) do if cv2[i].value == 2 then correctAddr2 = v.address; break end end
    if not correctAddr2 then return false end

    local pv2 = gg.getValues({{address = correctAddr2, flags = gg.TYPE_QWORD}})[1].value
    if pv2 == 0 then return false end
    pointer2 = tostring(pv2); savePointers()

    local fp = gg.getValues({{address = correctAddr2 + 0xA8, flags = gg.TYPE_QWORD}})[1].value
    if fp == 0 then return false end
    local na1 = tonumber(string.format("%016X", fp), 16)
    if not na1 then return false end
    local pv1 = gg.getValues({{address = na1, flags = gg.TYPE_QWORD}})[1].value
    if pv1 == 0 then return false end
    pointer1 = tostring(pv1); savePointers()

    gg.clearResults(); gg.searchNumber("54000", gg.TYPE_DWORD)
    local c4 = gg.getResultsCount()
    if c4 == 0 then gg.clearResults(); return false end
    if c4 > 10000 then gg.clearResults(); return false end
    local r4 = safeGetResults(c4) -- 🔒

    local chk4 = {}
    for _, x in ipairs(r4) do chk4[#chk4+1] = {address = x.address - 0x70, flags = gg.TYPE_DWORD}; chk4[#chk4+1] = {address = x.address - 0x74, flags = gg.TYPE_DWORD} end
    local cv4 = safeGetValues(chk4) -- 🔒
    local va = nil
    for i, x in ipairs(r4) do if cv4[(i-1)*2+1].value == 54000 and cv4[(i-1)*2+2].value == 18000 then va = x.address; break end end
    if not va then return false end

    local preCheck = gg.getValues({{address = va - 0x8, flags = gg.TYPE_DWORD}})[1].value
-- تم حذف الشرط: التعديل يُنفّذ دائماً بغض النظر عن القيمة
gg.setValues({
    {address = va - 0x78, flags = gg.TYPE_DWORD, value = 1},
    {address = va - 0x8,  flags = gg.TYPE_DWORD, value = 1}
})
monitorAddress1 = va - 0x78; monitorAddress2 = va - 0x8; monitorEditAddress1 = va - 0x68; monitorEditAddress2 = va + 0x8
lastMonitorValue1 = gg.getValues({{address = monitorAddress1, flags = gg.TYPE_DWORD}})[1].value
lastMonitorValue2 = gg.getValues({{address = monitorAddress2, flags = gg.TYPE_DWORD}})[1].value
monitoringEnabled = true; saveMonitoring(); savePointer1AddressesFromSearch()
gg.clearResults()
return true
end

local function extractTrainsPointer()
    gg.setVisible(false); gg.clearResults(); gg.searchNumber('1904', gg.TYPE_DWORD)
    local r = safeGetResults(1000) -- 🔒
    if #r == 0 then return false end
    local found = false
    for _, res in ipairs(r) do
        local a = res.address
        local vals = gg.getValues({
            {address = a - 0x8, flags = gg.TYPE_DWORD},
            {address = a + 0x8, flags = gg.TYPE_DWORD}
        })
        if vals[1].value ~= -8 or vals[2].value ~= 8 then goto continue end
        gg.loadResults({{address = a - 0x8, flags = gg.TYPE_QWORD}}); gg.searchPointer(0)
        local p3 = safeGetResults(10) -- 🔒
        if #p3 == 0 then goto continue end
        for _, p in ipairs(p3) do
            local a3 = p.address
            if gg.getValues({{address = a3 + 0x704, flags = gg.TYPE_DWORD}})[1].value ~= 1 then goto next_ptr end
            local pv = gg.getValues({{address = a3 + 0x740, flags = gg.TYPE_QWORD}})[1].value
            if pv and pv ~= 0 then
                pointerTrains = tostring(pv); saveTrainsPointer(); saveTrainAddressesFromPointer(pointerTrains)
                found = true; break
            end
            ::next_ptr::
        end
        if found then break end
        gg.clearResults() -- 🔒 في كل دورة
        ::continue::
    end
    gg.clearResults() -- 🔒 نهائي
    return found
end

local function eE()
    gg.toast("✈️ استدعاء طائرة المدينة إن كانت مغادرة... 🏙️")
    gg.sleep(1500)
    gg.toast("🚀 بدء المعالجة...")
    local r1 = extractPointer1(); local r2 = extractTrainsPointer()
    gg.clearResults() -- 🔒
    if r1 or r2 then gg.toast("🎉 تم كل شيء بنجاح ✨"); return true end
    gg.toast("😕 تعذّر إتمام العملية"); return false
end

-- ═══════════════════════════════════════════════════════════
-- التنفيذ
-- ═══════════════════════════════════════════════════════════
local function executePointer1()
    if #savedPointer1Addresses == 0 then return false end
    local mc = 0
    for _, a in ipairs(savedPointer1Addresses) do
        local cv = gg.getValues({{address = a - 0x8, flags = gg.TYPE_DWORD}})[1].value
        if cv == 65573 or cv == 65540 then
            gg.setValues({
                {address = a + 0x8,  flags = gg.TYPE_DWORD, value = productCount},
                {address = a + 0x10, flags = gg.TYPE_DWORD, value = selectedProduct.v1},
                {address = a + 0x14, flags = gg.TYPE_DWORD, value = selectedProduct.v2}
            })
            mc = mc + 1
        end
    end
    return mc > 0
end
local function executePointer2()
    if not pointer2 or pointer2 == "" then return false end
    gg.clearResults(); gg.searchNumber(pointer2, gg.TYPE_QWORD)
    local r = safeGetResults(9999) -- 🔒
    if #r == 0 then return false end
    local mc = 0
    for _, x in ipairs(r) do
        local cv = gg.getValues({{address = x.address - 0x8, flags = gg.TYPE_DWORD}})[1].value
        if cv == 65537 or cv == 65538 then gg.setValues({{address = x.address + 0x80, flags = gg.TYPE_DWORD, value = 1}}); mc = mc + 1 end
    end
    return mc > 0
end

local function executeTrainsPointem()
    if #savedTrainAddresses == 0 then return false end
    local ok = pcall(function()
        for _, b in ipairs(savedTrainAddresses) do
            gg.setValues({{address = b - 0x78, flags = gg.TYPE_FLOAT, value = 1},{address = b - 0x7C, flags = gg.TYPE_DWORD, value = 1},{address = b - 0x9C, flags = gg.TYPE_DWORD, value = 1},{address = b - 0xBC, flags = gg.TYPE_DWORD, value = 1},{address = b - 0xDC, flags = gg.TYPE_DWORD, value = 1},{address = b - 0xFC, flags = gg.TYPE_DWORD, value = 1}})
        end
    end)
    return ok
end

local function tafrighTrains()
    if not pointerTrains or pointerTrains == "" then
        gg.toast("⚠️ لا توجد بيانات قطارات، قم بالتحديث أولاً")
        return false
    end

    gg.clearResults()
    gg.searchNumber(pointerTrains, gg.TYPE_QWORD)
    local r = safeGetResults(9) -- 🔒 مسح فوري
    if #r == 0 then
        gg.toast("⚠️ لم يتم العثور على القطارات")
        return false
    end

    local ok = pcall(function()
        for _, v in ipairs(r) do
            local b = v.address
            gg.setValues({
                {address = b - 0x78, flags = gg.TYPE_FLOAT, value = 1},
                {address = b - 0x7C, flags = gg.TYPE_DWORD, value = 1},
                {address = b - 0x9C, flags = gg.TYPE_DWORD, value = 1},
                {address = b - 0xBC, flags = gg.TYPE_DWORD, value = 1},
                {address = b - 0xDC, flags = gg.TYPE_DWORD, value = 1},
                {address = b - 0xFC, flags = gg.TYPE_DWORD, value = 1}
            })
        end
    end)

    gg.clearResults() -- 🔒 تنظيف نهائي

    if ok then
        gg.toast("🚂 تم تفريغ القطارات")
    else
        gg.toast("😕 فشل التنفيذ")
    end
    return ok
end


local function executeTrainsPointer()
    if #savedTrainAddresses == 0 then return false end
    local ok = pcall(function()
        for _, b in ipairs(savedTrainAddresses) do
            local cv = gg.getValues({{address = b - 0x3C, flags = gg.TYPE_DWORD}})[1].value
            gg.setValues({{address = b - 0x78, flags = gg.TYPE_FLOAT, value = 1},{address = b - 0x7C, flags = gg.TYPE_DWORD, value = 1},{address = b - 0x9C, flags = gg.TYPE_DWORD, value = 1},{address = b - 0xBC, flags = gg.TYPE_DWORD, value = 1},{address = b - 0xDC, flags = gg.TYPE_DWORD, value = 1},{address = b - 0xFC, flags = gg.TYPE_DWORD, value = 1}})
            if cv == 1 then
                local v2Train1 = (selectedProduct == PRODUCT_WHEAT) and 1677751393 or selectedProduct.v2
                gg.setValues({
                    {address = b - 0x708, flags = gg.TYPE_DWORD, value = selectedProduct.v1},
                    {address = b - 0x704, flags = gg.TYPE_DWORD, value = v2Train1},
                    {address = b - 0x6F0, flags = gg.TYPE_DWORD, value = 0},
                    {address = b - 0x6EC, flags = gg.TYPE_DWORD, value = productCount},
                    {address = b - 0x5B0, flags = gg.TYPE_DWORD, value = 1},
                    {address = b - 0x480, flags = gg.TYPE_DWORD, value = 1},
                    {address = b - 0x350, flags = gg.TYPE_DWORD, value = 1},
                    {address = b - 0x220, flags = gg.TYPE_DWORD, value = 1}
                })
            elseif cv == 2 or cv == 3 then
                local baseOffs = {-0x708, -0x5D8, -0x4A8, -0x378, -0x248}
                local mods = {}
                for i = 1, 5 do
                    local base = b + baseOffs[i]
                    mods[#mods+1] = {address = base,        flags = gg.TYPE_DWORD, value = selectedProduct.v1}
                    mods[#mods+1] = {address = base + 0x4,  flags = gg.TYPE_DWORD, value = selectedProduct.v2}
                    mods[#mods+1] = {address = base + 0x18, flags = gg.TYPE_DWORD, value = 0}
                    mods[#mods+1] = {address = base + 0x1C, flags = gg.TYPE_DWORD, value = productCount}
                    mods[#mods+1] = {address = base + 0x48, flags = gg.TYPE_DWORD, value = 1}
                    mods[#mods+1] = {address = base + 0xE8, flags = gg.TYPE_DWORD, value = 0}
                end
                gg.setValues(mods)
            end
        end
    end)
    return ok
end

-- 🚂 الطلب من صناديق القطارات فقط
local function alatmer()
    if #savedTrainAddresses == 0 then
        gg.toast("⚠️ لا توجد بيانات قطارات، قم بالتحديث أولاً")
        return false
    end
    local ok = pcall(function()
        for _, b in ipairs(savedTrainAddresses) do
            local cv = gg.getValues({{address = b - 0x3C, flags = gg.TYPE_DWORD}})[1].value
            gg.setValues({
                {address = b - 0x78, flags = gg.TYPE_FLOAT, value = 1},
                {address = b - 0x7C, flags = gg.TYPE_DWORD, value = 1},
                {address = b - 0x9C, flags = gg.TYPE_DWORD, value = 1},
                {address = b - 0xBC, flags = gg.TYPE_DWORD, value = 1},
                {address = b - 0xDC, flags = gg.TYPE_DWORD, value = 1},
                {address = b - 0xFC, flags = gg.TYPE_DWORD, value = 1}
            })
            if cv == 1 or cv == 2 or cv == 3 then
                local baseOffs = {-0x708, -0x5D8, -0x4A8, -0x378, -0x248}
                local mods = {}
                for i = 1, 5 do
                    local base = b + baseOffs[i]
                    mods[#mods+1] = {address = base,        flags = gg.TYPE_DWORD, value = selectedProduct.v1}
                    mods[#mods+1] = {address = base + 0x4,  flags = gg.TYPE_DWORD, value = selectedProduct.v2}
                    mods[#mods+1] = {address = base + 0x18, flags = gg.TYPE_DWORD, value = 0}
                    mods[#mods+1] = {address = base + 0x1C, flags = gg.TYPE_DWORD, value = productCount}
                    mods[#mods+1] = {address = base + 0x48, flags = gg.TYPE_DWORD, value = 1}
                    mods[#mods+1] = {address = base + 0xE8, flags = gg.TYPE_DWORD, value = 0}
                end
                gg.setValues(mods)
            end
        end
    end)
    if ok then
        gg.toast("🚂 تم الطلب من صناديق القطارات فقط")
    else
        gg.toast("😕 فشل التنفيذ")
    end
    return ok
end

-- 🔔 إظهار طلب المساعدة (للقطارات المعلّقة) — البحث عبر pointerTrains
local function afhdt()
    if not pointerTrains or pointerTrains == "" then
        gg.toast("⚠️ لا توجد بيانات قطارات، قم بالتحديث أولاً")
        return false
    end

    gg.clearResults()
    gg.searchNumber(pointerTrains, gg.TYPE_QWORD)
    local r = safeGetResults(9) -- 🔒 مسح فوري
    if #r == 0 then
        gg.toast("⚠️ لم يتم العثور على القطارات")
        return false
    end

    local ok = pcall(function()
        for _, v in ipairs(r) do
            local b = v.address
            local cv = gg.getValues({{address = b - 0x3C, flags = gg.TYPE_DWORD}})[1].value
            if cv == 1 or cv == 2 or cv == 3 then
                gg.setValues({
                    {address = b - 0x78,  flags = gg.TYPE_FLOAT, value = 1},
                    {address = b - 0x6E0, flags = gg.TYPE_DWORD, value = 1},
                    {address = b - 0x5B0, flags = gg.TYPE_DWORD, value = 1},
                    {address = b - 0x480, flags = gg.TYPE_DWORD, value = 1},
                    {address = b - 0x350, flags = gg.TYPE_DWORD, value = 1},
                    {address = b - 0x220, flags = gg.TYPE_DWORD, value = 1}
                })
            end
        end
    end)

    gg.clearResults() -- 🔒 تنظيف نهائي

    if ok then
        gg.toast("✅ تم إظهار طلب المساعدة")
    else
        gg.toast("😕 فشل التنفيذ")
    end
    return ok
end

local function checkProductMonitoring()
    if not monitorAddress1 or not monitorAddress2 or not productMonitoringEnabled then return false end
    local ne, se = false, false
    local cv1 = gg.getValues({{address = monitorAddress1, flags = gg.TYPE_DWORD}})[1].value
    local cv2 = gg.getValues({{address = monitorAddress2, flags = gg.TYPE_DWORD}})[1].value
    if monitorEditAddress1 and lastMonitorValue1 == 0 and cv1 == 1 then
        gg.setValues({{address = monitorEditAddress1, flags = gg.TYPE_DWORD, value = 0}}); ne, se = true, true
    end
    if monitorEditAddress2 and lastMonitorValue2 == 0 and cv2 == 1 then
        gg.setValues({{address = monitorEditAddress2, flags = gg.TYPE_DWORD, value = 0}}); ne, se = true, true
    end
    lastMonitorValue1, lastMonitorValue2 = cv1, cv2
    if se then executeTrainsPointem() end
    return ne
end

-- مساعدة الاصدقاء 

local function executeTrainsPointer2()
    if not pointerTrains or pointerTrains == "" then return false end
    gg.clearResults(); gg.searchNumber(pointerTrains, gg.TYPE_QWORD)
    local r = safeGetResults(9) -- 🔒
    if #r == 0 then return false end
    local ok = pcall(function()
        local baseOffs = {-0x708, -0x5D8, -0x4A8, -0x378, -0x248}
        for _, v in ipairs(r) do
            local b = v.address
            local cv = gg.getValues({{address = b - 0x3C, flags = gg.TYPE_DWORD}})[1].value
            if cv == 1 or cv == 2 or cv == 3 then
                local mods = {}
                for i = 1, 5 do
                    local base = b + baseOffs[i]
                    mods[#mods+1] = {address = base + 0x48, flags = gg.TYPE_DWORD, value = 1}
                end
                gg.setValues(mods)
            end
        end
    end)
    return ok
end

local function executeAll()
    gg.toast("📦 جاري تنفيذ الطلبات... 🚀")
    local r1 = executeTrainsPointem()
    local r2 = executePointer1()
    local r3 = executePointer2(); gg.sleep(1000)
    local r4 = executeTrainsPointer()
    gg.clearResults() -- 🔒
    if r1 or r2 or r3 or r4 then gg.toast("🎉 تم التنفيذ بنجاح!"); return true end
    gg.toast("😕 لم يتغير شيء"); return false
end
local function executeAll2()
    local r1 = executePointer2(); local r2 = executeTrainsPointer2()
    gg.clearResults() -- 🔒
    if r1 or r2 then gg.toast("🎉 تم التنفيذ بنجاح!"); return true end
    gg.toast("😕 لم يتغير شيء"); return false
end
local function executeTrainsOnly()
    gg.setVisible(false)
    if #savedTrainAddresses == 0 then return false end
    local r1 = executeTrainsPointem(); gg.sleep(500); local r2 = executeTrainsPointer()
    gg.clearResults() -- 🔒
    return r1 or r2
end

local function Fshni8()
    local ti = gg.prompt({"🚂 رقم القطار (1-3):"}, {[1] = ""}, {[1] = "number"})
    if not ti or ti[1] == "" then gg.toast("❌ إلغاء"); return end
    local tn = math.floor(ti[1]); if tn < 1 or tn > 3 then gg.alert("❌ رقم غير صحيح"); return end
    if #savedTrainAddresses == 0 then gg.alert("❌ لا بيانات"); return end
    local fb
    for _, b in ipairs(savedTrainAddresses) do if gg.getValues({{address = b - 0x3C, flags = gg.TYPE_DWORD}})[1].value == tn then fb = b; break end end
    if not fb then gg.alert("❌ لم يتم العثور على القطار " .. tn); return end
    local boxes = {{n = "الأول", a1 = fb - 0x708, a2 = fb - 0x704},{n = "الثاني", a1 = fb - 0x5D8, a2 = fb - 0x5D4},{n = "الثالث", a1 = fb - 0x4A8, a2 = fb - 0x4A4},{n = "الرابع", a1 = fb - 0x378, a2 = fb - 0x374},{n = "الخامس", a1 = fb - 0x248, a2 = fb - 0x244}}
    local txt = ""
    for _, bx in ipairs(boxes) do
        local v1 = gg.getValues({{address = bx.a1, flags = gg.TYPE_DWORD}})[1].value
        local v2 = gg.getValues({{address = bx.a2, flags = gg.TYPE_DWORD}})[1].value
        txt = txt .. bx.n .. "\n;" .. v1 .. ";" .. v2 .. "\n\n"
    end
    gg.copyText(txt); gg.alert("✅ تم النسخ!\n🚂 القطار " .. tn .. "\n\n" .. txt)
end

local function unfreezePlane1()
    gg.setVisible(false); gg.clearResults(); gg.searchNumber("54000", gg.TYPE_DWORD)
    local count = gg.getResultsCount(); if count == 0 then gg.clearResults(); return false end
    local results = safeGetResults(count) -- 🔒
    local modifications = {}
    for _, r in ipairs(results) do
        local addr = r.address
        if gg.getValues({{address = addr - 0x74, flags = gg.TYPE_DWORD}})[1].value == 18000 then
            table.insert(modifications, {address = addr + 0x4,  flags = gg.TYPE_DWORD, value = 0})
            table.insert(modifications, {address = addr - 0x6C, flags = gg.TYPE_DWORD, value = 1})
            table.insert(modifications, {address = addr - 0x78, flags = gg.TYPE_DWORD, value = 1})
        end
    end
    if #modifications > 0 then gg.setValues(modifications); gg.toast("✅ تم") else gg.toast("⚠️ لا شيء") end
    gg.clearResults() -- 🔒
    return true
end
local function freezePlane()
    gg.setVisible(false); gg.clearResults(); gg.searchNumber("54000", gg.TYPE_DWORD)
    if gg.getResultsCount() == 0 then gg.clearResults(); return false end
    local r = safeGetResults(nil) -- 🔒 (nil = الكل)
    local m, fc = {}, 0
    for _, x in ipairs(r) do
        if gg.getValues({{address = x.address - 0x70, flags = gg.TYPE_DWORD}})[1].value == 54000 then
            local v8 = gg.getValues({{address = x.address + 0x4, flags = gg.TYPE_DWORD}})[1].value
            if v8 == 1 then
                table.insert(m, {address = x.address + 0x4, flags = gg.TYPE_DWORD, value = 0})
                table.insert(m, {address = x.address - 0x78, flags = gg.TYPE_DWORD, value = 0})
                fc = fc + 1
            elseif v8 == 0 then
                table.insert(m, {address = x.address - 0x8, flags = gg.TYPE_DWORD, value = 0})
                table.insert(m, {address = x.address - 0x6C, flags = gg.TYPE_DWORD, value = 0})
                fc = fc + 1
            end
        end
    end
    if #m > 0 then gg.setValues(m); gg.toast("❄️ تم") else gg.toast("❌ لا شيء") end
    gg.clearResults() -- 🔒
    return fc > 0
end
local function unfreezePlane()
    gg.setVisible(false); gg.clearResults(); gg.searchNumber("54000", gg.TYPE_DWORD)
    if gg.getResultsCount() == 0 then gg.clearResults(); return false end
    local r = safeGetResults(nil) -- 🔒
    local m = {}
    for _, x in ipairs(r) do
        if gg.getValues({{address = x.address - 0x70, flags = gg.TYPE_DWORD}})[1].value == 54000 then
            table.insert(m, {address = x.address + 0x4, flags = gg.TYPE_DWORD, value = 1})
            table.insert(m, {address = x.address - 0x6C, flags = gg.TYPE_DWORD, value = 1})
        end
    end
    if #m > 0 then gg.setValues(m); gg.toast("✅ تم") else gg.toast("⚠️ لا شيء") end
    gg.clearResults() -- 🔒
    return true
end


-- ترقية الى قائد مساعد


local function resaveAddresses()
    local ok = false
    if pointerTrains and pointerTrains ~= "" then saveTrainAddressesFromPointer(pointerTrains); ok = true end
    if pointer1 and pointer1 ~= "" then savePointer1AddressesFromSearch(); ok = true end
    gg.clearResults() -- 🔒
    if ok then gg.toast("🎉 تم التحديث بنجاح!"); return true end
    return false
end

-- 🔄 الخيار الموحّد
local function updateIndicators()
    if pointer1 and pointer1 ~= "" and pointerTrains and pointerTrains ~= "" then
        return resaveAddresses()
    end
    return eE()
end

local function promoteToAssistant()
    gg.setVisible(false)
    gg.clearResults()
    
    local input = gg.prompt(
        {"🏙 اكتب مستوى مدينتك الحالي:"},
        {""},
        {"number"}
    )
    if not input then return end
    
    local level = tostring(input[1])
    
    gg.searchNumber("1;1;1;" .. level .. ";500~560;500~540::37", gg.TYPE_DWORD)
    gg.refineNumber("1", gg.TYPE_DWORD)
    
    local results = gg.getResults(10000)
    if #results == 0 then
        gg.alert([[
❌ لم يتم العثور على النتائج.

يرجى التأكد من:
• فتح اللعبة وربطها مع الاسكريبت.
• اختيار نطاقات الذاكرة الصحيحة.
• اغلق اللعبة واعد تشغيلها وجرب مره تانيه.
]])
        return
    end
    
    local t = {}
    for i, v in ipairs(results) do
        table.insert(t, {address = v.address, flags = gg.TYPE_DWORD, value = 3, freeze = false})
    end
    gg.setValues(t)
    gg.clearResults()
    gg.toast("تم ترقيتك الى قائد مساعد بنجاح ✅️")
    gg.setVisible(false)
end

-- 👬 مساعدة الأصدقاء الآمنة: تطلب إيقاف المراقبة مؤقتاً
local function safeFriendHelp()
    gg.alert("⏸️ لطفاً أوقف المراقبة مؤقتاً قبل المتابعة\n\n💡 من: 📊 إيقاف المراقبة", "حسناً")
    return executeAll2()
end

local function checkMonitoring()
    if not monitorAddress1 or not monitorAddress2 or not monitoringEnabled then return false end
    local ne = false
    local cv1 = gg.getValues({{address = monitorAddress1, flags = gg.TYPE_DWORD}})[1].value
    local cv2 = gg.getValues({{address = monitorAddress2, flags = gg.TYPE_DWORD}})[1].value
    if monitorEditAddress1 and lastMonitorValue1 == 0 and cv1 == 1 then gg.setValues({{address = monitorEditAddress1, flags = gg.TYPE_DWORD, value = 0}}); ne = true end
    if monitorEditAddress2 and lastMonitorValue2 == 0 and cv2 == 1 then gg.setValues({{address = monitorEditAddress2, flags = gg.TYPE_DWORD, value = 0}}); ne = true end
    lastMonitorValue1, lastMonitorValue2 = cv1, cv2
    if ne then executeAll() end
    return ne
end

local function loadAllData()
    loadPointers(); loadMonitoring(); loadTrainsPointer()
    loadTrainAddresses(); loadPointer1Addresses()
end

local function toggleMonitoring()
    if monitoringEnabled then
        monitoringEnabled = false; productMonitoringEnabled = false
        monitorAddress1 = nil; monitorAddress2 = nil
        monitorEditAddress1 = nil; monitorEditAddress2 = nil
        lastMonitorValue1, lastMonitorValue2 = 0, 0
        gg.clearResults() -- 🔒
        gg.toast("💤 تم الإيقاف")
    else
        if not pointer1 or pointer1 == "" then gg.toast("⚠️ يرجى التحديث أولاً"); return end
        loadMonitoring()
        if not monitorAddress1 or not monitorAddress2 then gg.toast("⚠️ يرجى التحديث أولاً"); return end
        monitoringEnabled = true; productMonitoringEnabled = true
        gg.clearResults() -- 🔒
        gg.toast("✨ تم التفعيل")
    end
end

-- 🧹 تنظيف الملفات + النتائج عند الخروج
local function cleanupFiles()
    pcall(function() gg.clearResults() end) -- 🔒
    pcall(function() os.remove(pointersFile) end)
    pcall(function() os.remove(monitoringFile) end)
    pcall(function() os.remove(trainsPointerFile) end)
    pcall(function() os.remove(trainAddressesFile) end)
    pcall(function() os.remove(pointer1AddressesFile) end)
end

-- 🔔 إظهار طلب المساعدة (مع التعليمات)
local function showHelpRequest()
    -- 📋 الشاشة الأولى: التعليمات قبل التنفيذ
    local c = gg.alert([[
🔔 إظهار طلب المساعدة

هذا العمل للمزارع التي لا تستطيع طلب المساعدة منها فقط.

إذا كانت مزرعتك لا تستطيع الطلب منها يدوياً أو تدخل على القطارات وتعلق، فاستمع مني جيداً:

1️⃣ ادخل إلى أي مزرعة صديق تكون قطاراته أو أحد قطاراته على الأقل وطائراته متواجدة في مزرعته.

2️⃣ عد من هذا الخيار وقم باستخدام خيار:
   🔄 تحديث قيم الطائرة والقطارات

3️⃣ بعد تحديث القيم قم بإيقاف المراقبة (📊 إيقاف المراقبة).

4️⃣ عد من مزرعة صديقك الى مزرعتك 

5️⃣ إذا كانت قطاراتك معلقة لا تدخل عليها — استخدم هذا الخيار قبل أن تدخل عليها.
]], "✅ فهمت - متابعة", "❌ إلغاء")

    if c ~= 1 then return end

    if not afhdt() then return end

    -- 📋 الشاشة الثانية: التعليمات بعد التنفيذ
    gg.alert([[
✅ تم إزالة التجميد الخطوه الاولى 


📌 الآن تأكد من أن القطارات عادت إلى مزرعتك، ثم اختر خيار:


تفريغ صناديق القطار من المنتجات 

📌 بعد تفريغ الصناديق تاكد من تفريغها  وبعدها اختار 

   👬 مساعدة الأصدقاء الآمنة

📌 بعد أن يتم الطلب من قطاراتك والطائرة، ادخل إلى الخريطة المغامرة، أو قم بتغيير لغة الهاتف واطلب من الأصدقاء مساعدتك في الثطار الاول

📌 وإن لم تظهر عندهم الطلبات، فاخرج من اللعبة وعد إليها — وبعدعا ادخل على قائمة الأصدقاء وساعد ارني

🍀 موفق يا الغالي 🍀
]], "حسناً")
end

showPlaneTrainMenu = function()
    currentMenuFn = showPlaneTrainMenu
    gg.clearResults()
    local productLabel = selectedProduct.name
    if selectedProduct == PRODUCT_CROWN then productLabel = productLabel .. " × " .. productCount end
    local items = {
        "↩️ رجـــــــــــــــــــــــــــــــــوع",
        "⚡ الطلـــب يدويـــاً مـــن كـــل صناديـــق الطائـــرة والقطـــارات",
        "🚂 الطلـــب مـــن صناديـــق القطـــارات فقـــط",
        "🔄 تحديـــث قيـــم الطائـــرة والقطـــارات",
        "👬 مساعـــدة الأصـــدقاء الآمنـــة",
        "📊 " .. (monitoringEnabled and "إيقـــاف" or "تفعيـــل") .. " المراقبـــة",
        "🏅 الترقيـــة إلـــى قائـــد مساعـــد",
        "🌾 التبـــديل بيـــن القمـــح والتـــاج (" .. productLabel .. ")",
        "🔔 إظهـــار طلـــب المساعـــدة",
        "🚂 تفريـــغ القطـــارات مـــن المنتجـــات",
        "❌ الخـــــــروج"
    }
    local c = gg.choice(items, nil, "✈️ الطائرة والقطار 🚂")
    if not c or c == 1 then currentMenuFn = showMainMenu; return showMainMenu() end
    if     c == 2  then executeAll()
    elseif c == 3  then alatmer()
    elseif c == 4  then updateIndicators()
    elseif c == 5  then safeFriendHelp()
    elseif c == 6  then toggleMonitoring()
    elseif c == 7  then promoteToAssistant()
    elseif c == 8  then askProductChoice()
    elseif c == 9  then showHelpRequest()
    elseif c == 10 then tafrighTrains()
    elseif c == 11 then cleanupFiles(); gg.toast("👋 مع السلامة ✨"); os.exit() end
end

-- ═══════════════════════════════════════════════════════════
-- 🚤 قسم السباق - النسخة الكاملة المستقلة
-- ═══════════════════════════════════════════════════════════
-- ⚠️ ضع هذا القسم كاملاً قبل showMainMenu
-- ⚠️ يوفر دوال متوافقة مع الكود القديم:
--    loadCityValue, saveCityValue, loadCooperationValue,
--    loadCoopCities, saveCoopCities, cooperationValue_global
-- ═══════════════════════════════════════════════════════════

-- ───────────── المتغيرات المشتركة (globals للتوافق) ─────────────
local lastRaceMonitorAddress = nil

-- ───────────── دوال حفظ/تحميل متوافقة مع الكود القديم ─────────────
function saveCityValue(v)
    local f = io.open("/sdcard/city_value.txt", "w")
    if f then f:write(tostring(v)); f:close(); return true end
    return false
end

function loadCityValue()
    local f = io.open("/sdcard/city_value.txt", "r")
    if f then local v = f:read("*all"); f:close(); return tonumber(v) end
    return nil
end

function saveCooperationValue(v)
    local f = io.open("/sdcard/cooperation_value.txt", "w")
    if f then f:write(tostring(v)); f:close(); return true end
    return false
end

function loadCooperationValue()
    local f = io.open("/sdcard/cooperation_value.txt", "r")
    if f then local v = f:read("*all"); f:close(); return tonumber(v) end
    return nil
end


savedCoopCities = savedCoopCities or {}   -- ✅ إصلاح: تعريف المتغير كـ global
function loadCoopCities() savedCoopCities = {} end
function saveCoopCities() return true end

-- ───────────── التحقق من القيم المحملة ─────────────
cooperationValue_global = cooperationValue_global or loadCooperationValue() or nil
cityMissionValue = cityMissionValue or loadCityValue() or nil

-- ═══════════════════════════════════════════════════════════
-- (A) استخراج قيمة المدينة - للمرة الأولى فقط
-- ═══════════════════════════════════════════════════════════
local function extractCityValueFromMission()
    gg.setVisible(false)
    gg.clearResults()
    gg.toast("ملاحظة: يجب أن يكون جهازك متصل بالإنترنت")

    local dir = (gg.getFile() or ""):match("^(.*)/") or "/sdcard"
    local savePath = dir .. "/city_level_last.txt"

    local lastLevel = ""
    local f = io.open(savePath, "r")
    if f then lastLevel = (f:read("*a") or ""):gsub("%s+", ""); f:close() end

    local input = gg.prompt(
        { "أدخل مستوى مدينتك:\n\nملاحظة: يجب أن يكون جهازك متصل بالإنترنت" },
        { lastLevel },
        { "number" }
    )
    if not input or not input[1] then return false, nil end

    local level = tonumber(input[1])
    if not level or level <= 0 then return false, nil end
    level = math.floor(level)

    local sf = io.open(savePath, "w")
    if sf then sf:write(tostring(level)); sf:close() end

    local searchStr = "1;1;1~3;" .. string.format("%d", level) .. ";500~600::25"
    gg.searchNumber(searchStr, gg.TYPE_DWORD)

    local count = gg.getResultsCount()
    if count == 0 then
        gg.clearResults()
        gg.alert("❌ لا نتائج\nالنمط: " .. level ..
                 "\n\nتحقق من المستوى، الشاشة، والاتصال")
        return false, nil
    end

    local results = gg.getResults(count)
    gg.clearResults()
    if not results or #results == 0 then return false, nil end

    local firstAddr = nil
    local checkList = {}
    for i = 1, #results do
        checkList[i] = { address = results[i].address + 0xC, flags = gg.TYPE_DWORD }
    end
    local lv = gg.getValues(checkList)
    for i = 1, #results do
        if lv[i] and tonumber(lv[i].value) == level then
            firstAddr = results[i].address
            break
        end
    end
    firstAddr = firstAddr or results[1].address

    local cv = gg.getValues({{ address = firstAddr - 0x80, flags = gg.TYPE_DWORD }})[1]
    local cityValue = cv and cv.value or nil

    if not cityValue then
        gg.alert("⚠️ فشل قراءة -0x8C")
        return false, nil
    end

    cityMissionValue = cityValue
    saveCityValue(cityValue)
    gg.clearResults()
    
    -- ✅ تعديل مهم: إرجاع true مع القيمة
    return true, cityValue 
end

-- ═══════════════════════════════════════════════════════════
-- (B) البحث الرئيسي عن المؤشر (لا يحتاج أي معامل)
-- ═══════════════════════════════════════════════════════════
local function mainPointerSearch()
    gg.setVisible(false); gg.clearResults()
    gg.searchNumber("-216", gg.TYPE_DWORD)
    local c = gg.getResultsCount()
    if c == 0 then gg.toast("❌ لا نتائج"); gg.clearResults(); return false end
    local r = gg.getResults(c)
    gg.clearResults()

    local cl = {}
    for _, x in ipairs(r) do table.insert(cl, {address = x.address + 0x8, flags = gg.TYPE_DWORD}) end
    local cv = gg.getValues(cl); local va
    for i, v in ipairs(cv) do if v.value == 328 then va = r[i].address; break end end
    if not va then gg.toast("❌ لا نتيجة صحيحة"); return false end

    gg.loadResults({{address = va, flags = gg.TYPE_QWORD}})
    gg.searchPointer(0)
    local pr = gg.getResults(gg.getResultsCount())
    if #pr == 0 then gg.toast("❌ لا نتائج"); gg.clearResults(); return false end
    gg.clearResults()

    -- ✅ تحقق جماعي قبل التعديل
    local chk = {}
    for _, x in ipairs(pr) do
        table.insert(chk, {address = x.address - 0x8, flags = gg.TYPE_DWORD})
    end
    local curVals = gg.getValues(chk)

    local el = {}
    for i, x in ipairs(pr) do
        if curVals[i].value >= -1 and curVals[i].value <= 80000 then
            table.insert(el, {address = x.address - 0x8, flags = gg.TYPE_DWORD, value = 1})
        end
    end

    if #el > 0 then
        gg.setValues(el)
        gg.toast("✅ تم التعديل " .. #el .. "/" .. #pr)
        return true
    else
        gg.toast("⚠️ لا قيم مطابقة")
        return false
    end
end

-- ═══════════════════════════════════════════════════════════
-- (C) إيجاد المراقبة (يعمل في كل الأحوال)
-- ═══════════════════════════════════════════════════════════
local function findRaceMonitor()
    if not cityMissionValue then return false end

    gg.clearResults()
    gg.searchNumber(cityMissionValue, gg.TYPE_DWORD)
    local all = gg.getResults(150000)
    gg.clearResults()
    if #all == 0 then return false end

    -- فحص جماعي: -0x4 و -0x8 كلاهما -1
    local checkList = {}
    for _, v in ipairs(all) do
        table.insert(checkList, {address = v.address - 0x4, flags = gg.TYPE_DWORD})
        table.insert(checkList, {address = v.address - 0x8, flags = gg.TYPE_DWORD})
    end
    local vals = gg.getValues(checkList)

    local monitorAddr = nil
    for i, v in ipairs(all) do
        local idx = (i - 1) * 2 + 1
        if vals[idx].value == -1 and vals[idx + 1].value == -1 then
            monitorAddr = v.address + 0xB0
            break
        end
    end

    if not monitorAddr then
        gg.alert("⚠️ المستخدم الكريم\n\n" ..
                 "لم نجد قيمة مراقبة صالحة.\n\n" ..
                 "• تأكد من نطاقات الذاكرة\n" ..
                 "• تأكد من تشغيل الإنترنت\n" ..
                 "• إذا استمرت المشكلة أغلق اللعبة وحاول مجدداً")
        return false
    end

    lastRaceMonitorAddress = monitorAddr

    -- تجنب التغير الوهمي إذا كانت المراقبة = 1
    local cv = gg.getValues({{address = monitorAddr, flags = gg.TYPE_DWORD}})[1].value
    if cv == 1 then
        gg.toast("⚠️ المراقبة = 1، ننتظر إعادة التعيين...")
        while cv == 1 do
            gg.sleep(100)
            cv = gg.getValues({{address = monitorAddr, flags = gg.TYPE_DWORD}})[1].value
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════
-- تهيئة ما قبل البحث (تصفير المهام الموجودة)
-- ═══════════════════════════════════════════════════════════
local function prepareBeforeSearch()
    gg.setVisible(false)
    gg.clearResults()
    if not cityMissionValue then
        gg.alert("❌ لا قيمة مدينة محفوظة!")
        return 0
    end

    gg.toast("🗑️ تهيئة ما قبل البحث...")
    gg.searchNumber(cityMissionValue, gg.TYPE_DWORD)
    local all = gg.getResults(90000)
    gg.clearResults()
    if #all == 0 then
        gg.toast("❌ لم نجد أي مهام في مخزنك")
        return 0
    end
    if #all >= 90000 then
        gg.toast("⚠️ النتائج كثيرة جداً")
        return 0
    end

    -- فلترة المهام الصالحة
    local valid, rl = {}, {}
    for _, r in ipairs(all) do
        table.insert(rl, {address = r.address - 0xA8, flags = gg.TYPE_DWORD})
    end
    local v = gg.getValues(rl)
    for i = 1, #all do
        if v[i].value == 65538 or v[i].value == 65539 then
            table.insert(valid, all[i].address)
        end
    end
    if #valid == 0 then
        gg.toast("⚠️ لا مهام صالحة")
        return 0
    end

    -- تصفير المهام
    local mods, ql = {}, {}
    for _, a in ipairs(valid) do
        table.insert(mods, {address = a + 0x20, flags = gg.TYPE_DWORD, value = 0})
        table.insert(mods, {address = a + 0x24, flags = gg.TYPE_DWORD, value = 0})
        table.insert(ql, {address = a + 0x160, flags = gg.TYPE_QWORD})
    end
    local qv = gg.getValues(ql)
    for _, q in ipairs(qv) do
        local na = tonumber(string.format("%016X", q.value), 16)
        if na then
            table.insert(mods, {address = na,      flags = gg.TYPE_DWORD, value = 0})
            table.insert(mods, {address = na + 0x4, flags = gg.TYPE_DWORD, value = 150})
        end
    end
    if #mods > 0 then gg.setValues(mods) end
    gg.clearResults()
    return #valid
end

-- ═══════════════════════════════════════════════════════════
-- انتظار جمع 101 مهمة عبر المراقبة
-- ═══════════════════════════════════════════════════════════
local function waitForMissions(targetCount, currentCount)
    if currentCount >= targetCount then return true end
    if not lastRaceMonitorAddress then return false end

    local lastValue = gg.getValues({{address = lastRaceMonitorAddress, flags = gg.TYPE_DWORD}})[1].value
    local taken = currentCount
    local safety = 0

    while taken < targetCount and safety < 10000 do
        local newValue = gg.getValues({{address = lastRaceMonitorAddress, flags = gg.TYPE_DWORD}})[1].value
        if lastValue == 0 and newValue == 1 then
            taken = taken + 1
            local remaining = targetCount - taken
            if remaining > 0 then
                gg.toast("✅ مهمة " .. taken .. " — المتبقي " .. remaining)
            end
        end
        lastValue = newValue
        safety = safety + 1
        gg.sleep(100)
    end
    return taken >= targetCount
end

-- ═══════════════════════════════════════════════════════════
-- إعادة المهام إلى وضعها الطبيعي (1 → 7200)
-- ═══════════════════════════════════════════════════════════
local function restoreMissionsNormal()
    gg.setVisible(false)
    gg.clearResults()
    gg.searchNumber("-216", gg.TYPE_DWORD)
    local c = gg.getResultsCount()
    if c == 0 then gg.clearResults(); gg.toast("لا يوجد نتائج مطابقة "); return false end
    local r = gg.getResults(c)
    gg.clearResults()

    -- ✅ قراءة جماعية +0x8 للبحث عن 328
    local checkList = {}
    for _, x in ipairs(r) do
        table.insert(checkList, {address = x.address + 0x8, flags = gg.TYPE_DWORD})
    end
    local cv = gg.getValues(checkList)

    local va = nil
    for i, v in ipairs(cv) do
        if v.value == 328 then va = r[i].address; break end
    end
    if not va then gg.toast("لا يوجد نتائج في البحث الثاني "); return false end

    -- 🎯 searchPointer من 328
    gg.loadResults({{address = va, flags = gg.TYPE_QWORD}})
    gg.searchPointer(0)
    local pr = gg.getResults(gg.getResultsCount())
    if #pr == 0 then gg.toast("❌ لا نتائج بعد searchPointer"); gg.clearResults(); return false end
    gg.clearResults()

    -- ✅ التحقق الجماعي قبل التعديل
    local chk = {}
    for _, x in ipairs(pr) do
        table.insert(chk, {address = x.address - 0x8, flags = gg.TYPE_DWORD})
    end
    local curVals = gg.getValues(chk)

    -- ✅ تعديل فقط القيم == 1 → 7200
    local edits = {}
    for i, x in ipairs(pr) do
        if curVals[i].value == 1 then
            table.insert(edits, {address = x.address - 0x8, flags = gg.TYPE_DWORD, value = 7200})
        end
    end
    if #edits > 0 then
        gg.setValues(edits)
        gg.toast("✅ تم استعادة " .. #edits .. "/" .. #pr .. " إلى الى وضعها الاساسي")
    else
        gg.toast("⚠️ لا يوجد قيم تحتاج الى اعادة")
    end
    gg.clearResults()
    return #edits > 0
end

-- ═══════════════════════════════════════════════════════════
-- تنفيذ المهام
-- ═══════════════════════════════════════════════════════════
local function executeMissions()
    gg.setVisible(false)
    gg.clearResults()
    if not cityMissionValue then
        gg.alert("❌ لا قيمة مدينة محفوظة!")
        return false
    end

    gg.searchNumber(cityMissionValue, gg.TYPE_DWORD)
    local all = gg.getResults(5000)
    gg.clearResults()
    if #all == 0 then
        gg.toast("❌ لا نتائج")
        return false
    end

    -- فحص جماعي لكل القيم
    local valid, rl = {}, {}
    for _, r in ipairs(all) do
        table.insert(rl, {address = r.address - 0xA8, flags = gg.TYPE_DWORD})
        table.insert(rl, {address = r.address + 0x18, flags = gg.TYPE_DWORD})
        table.insert(rl, {address = r.address + 0x1C, flags = gg.TYPE_DWORD})
        table.insert(rl, {address = r.address + 0x160, flags = gg.TYPE_QWORD})
    end
    local v = gg.getValues(rl)

    for i = 1, #all do
        local idx = (i - 1) * 4 + 1
        if v[idx].value == 65538 or v[idx].value == 65539 then
            local x = bit32.bxor(v[idx + 1].value, v[idx + 2].value)
            if x >= 1 and x <= 1500 then
                table.insert(valid, {address = all[i].address, qword = v[idx + 3].value})
            end
        end
    end
    if #valid == 0 then
        gg.alert("⚠️ لا نتائج صالحة للتنفيذ")
        return false
    end

    local mods, count = {}, 0
    for i, d in ipairs(valid) do
        if i > 101 then break end
        local a = d.address
        
        table.insert(mods, {address = a + 0x18,   flags = gg.TYPE_DWORD, value = 0})
        table.insert(mods, {address = a + 0x20,   flags = gg.TYPE_DWORD, value = 0})
        table.insert(mods, {address = a + 0x1C,   flags = gg.TYPE_DWORD, value = 5})
        table.insert(mods, {address = a + 0x24,   flags = gg.TYPE_DWORD, value = 5})
        local na = tonumber(string.format("%016X", d.qword), 16)
        if na then
            table.insert(mods, {address = na,      flags = gg.TYPE_DWORD, value = 0})
            table.insert(mods, {address = na + 0x4, flags = gg.TYPE_DWORD, value = 150})
        end
        count = count + 1
    end

    if #mods > 0 then gg.setValues(mods) end
    gg.clearResults()
    gg.alert("🎉 نجاح!\n\n" ..
             "✅ تم تنفيذ " .. count .. " مهمة\n\n" ..
             "مبروك! خذ مهمة واحذفها لكي يتم احتساب المهام ✨")
    return true
end




-- ═══════════════════════════════════════════════════════════
-- الدالة الرئيسية: تهيئة المهام وتنفيذها
-- ═══════════════════════════════════════════════════════════
local function setupAndExecuteMissions()
    -- 1) تحذير ترحيبي
    gg.toast("أخي الكريم، لكي لا تتعرض للحظر الرجاء الالتزام بتعليمات المطور.\nحظاً موفقاً 🌟")
    gg.sleep(2500)

    -- 2) سؤال قفزة الوقت
    local tj = gg.choice({
        "✅ نعم، قمت بقفزة الوقت",
        "❓ لا أعرف، أظهر التعليمات"
    }, nil,
        "⚠️ تنبيه هام:\n\n" ..
        "يجب أن تعمل (قفزة وقت) لمدة يوم كامل قبل استخدام هذه الدالة.\n\n" ..
        "هل قمت بعمل قفزة الوقت؟")

    if not tj then return end
    if tj == 2 then
        gg.alert(
            "📖 تعليمات عمل قفزة وقت:\n\n" ..
            "1️⃣ قم بالخروج من الاسكربت من زر الخروج.\n" ..
            "2️⃣ من ايقونة الجيم الجاردن العائمة ادخل عليها.\n" ..
            "3️⃣ اضغط على 3 خطوط فوق يسار الشاشة جوار صورة اللعبة، ستظهر قائمة اعدادات.\n" ..
            "4️⃣ سطر (تهكير السرعه اعتراض) تحت سطر (اختر نطاقات الذاكره)، تأكد أن المربعات عليها صح إلى المربع السابع.\n" ..
            "5️⃣ عد لقائمة الضبط وادخل على (عرض لوحة قفزة الوقت).\n" ..
            "6️⃣ بدّل الخيار إلى (نعم).\n" ..
            "7️⃣ سيظهر مربع عائم صغير على الشاشة، اضغط عليه وادخل (1:1:1:1) أو (86400).",
            "حسناً، فهمت")
        return
    end

    -- 3) إشعار عام (بدون ذكر المدينة)
    gg.toast("⚙️ جاري بدء العمل وتهيئة السباق...")

    -- 4) استخراج قيمة المدينة (صامت)
    local ok, cityValue = extractCityValueFromMission()
    if not ok or not cityValue then
        gg.alert("⚠️ فشل في تهيئة السباق\n\n" ..
                 "تأكد من وجود مهمة نشطة في قسم السباق ثم حاول مجدداً")
        return
    end

    -- ✅ حفظ صامت بدون إشعار
    cityMissionValue = cityValue
    saveCityValue(cityMissionValue)

    -- 5) البحث الرئيسي
    gg.toast("🔍 جاري التهيئة...")
    if not mainPointerSearch() then
        gg.alert("⚠️ فشل في البحث الرئيسي\n\nتأكد من فتح قسم السباق ثم أعد المحاولة")
        return
    end

    -- 6) إيجاد المراقبة
    if not findRaceMonitor() then return end

    -- 7) تهيئة ما قبل البحث (أول مرة)
    local found = prepareBeforeSearch()
    if found == 0 then
        gg.alert("⚠️ لم نجد أي مهام في مخزنك\n\n" ..
                 "تأكد من أنك أخذت مهمة واحدة على الأقل ثم حاول مجدداً")
        return
    end

    gg.alert("📊 لقد وجدنا في مخزنك " .. found .. " مهمة\n\n" ..
             "🎯 الهدف: 101 مهمة\n\n" ..
             "استمر بأخذ المهام من اللعبة، وسنراقب تلقائياً.")

    -- 8) انتظار جمع 101 مهمة
    local reached = waitForMissions(101, found)
    if reached then
        gg.toast("🎉 وصلت إلى 101 مهمة!")
    else
        gg.alert("⚠️ انتهى وقت الانتظار\n\n" ..
                 "تأكد من أنك تأخذ المهام بسرعة كافية")
        return
    end

    -- 9) تهيئة ما قبل البحث (ثانية)
    gg.toast("🗑️ تهيئة ما قبل البحث النهائية...")
    prepareBeforeSearch()

    -- 10) إعادة المهام إلى وضعها الطبيعي
    gg.toast("🔄 إعادة المهام إلى وضعها الطبيعي...")
    restoreMissionsNormal()

    -- 11) تنفيذ المهام
    gg.toast("✨ جاري تنفيذ المهام...")
    executeMissions()
end
-- ═══════════════════════════════════════════════════════════
-- 💰 تطبيق قيم النقود على النتائج الصالحة (جميع الصناديق)
-- ═══════════════════════════════════════════════════════════
local function applyMoneyValues()
    gg.setVisible(false)
    gg.clearResults()
    gg.searchNumber("-216", gg.TYPE_DWORD)
    local c = gg.getResultsCount()
    if c == 0 then
        gg.toast("❌ لا نتائج")
        gg.clearResults()
        gg.setVisible(true)
        return false
    end
    local r = gg.getResults(c)
    gg.clearResults()

    local cl = {}
    for _, x in ipairs(r) do
        table.insert(cl, {address = x.address + 0x8, flags = gg.TYPE_DWORD})
    end
    local cv = gg.getValues(cl)
    local va
    for i, v in ipairs(cv) do
        if v.value == 328 then
            va = r[i].address
            break
        end
    end
    if not va then
        gg.setVisible(true)
        gg.alert("❌ لا نتيجة صحيحة")
        return false
    end

    gg.loadResults({{address = va, flags = gg.TYPE_QWORD}})
    gg.searchPointer(0)
    local pr = gg.getResults(gg.getResultsCount())
    if #pr == 0 then
        gg.setVisible(true)
        gg.alert("❌ لا نتائج")
        gg.clearResults()
        return false
    end
    gg.clearResults()

    -- ═══════════════════════════════════════════════════════════
    -- [المرحلة 1] إيجاد القالب (Template)
    -- ═══════════════════════════════════════════════════════════
    local tplChecks = {}
    for _, x in ipairs(pr) do
        table.insert(tplChecks, {address = x.address - 0xC8, flags = gg.TYPE_DWORD})
        table.insert(tplChecks, {address = x.address - 0xD8, flags = gg.TYPE_DWORD})
    end
    local tplVals = gg.getValues(tplChecks)

    local template = nil
    for i = 1, #pr do
        local c8 = tplVals[(i - 1) * 2 + 1].value
        local d8 = tplVals[(i - 1) * 2 + 2].value
        if c8 == 1768907534 and d8 >= 65547 and d8 <= 65553 then
            template = pr[i].address
            break
        end
    end

    if not template then
        gg.setVisible(true)
        gg.alert("❌ لم يتم العثور على النتيجة المصدر (القالب)")
        return false
    end

    -- ═══════════════════════════════════════════════════════════
    -- [المرحلة 2] نسخ قيم القالب من -0xE8 إلى +0x78  (89 قيمة)
    -- ═══════════════════════════════════════════════════════════
    local OFFSET_START = -0xE8
    local OFFSET_END   = 0x78
    local VALUE_COUNT  = (OFFSET_END - OFFSET_START) / 4 + 1   -- = 89

    local copyList = {}
    for k = 0, VALUE_COUNT - 1 do
        table.insert(copyList, {
            address = template + OFFSET_START + k * 4,
            flags   = gg.TYPE_DWORD
        })
    end
    local copied = gg.getValues(copyList)

    local templateValues = {}
    for i = 1, #copied do
        templateValues[i] = copied[i].value
    end

    -- ⚠️ تأكيد
    if gg.alert(
        "⚠️ نسخ القيم من القالب وتبديلها على جميع النتائج؟\n\n" ..
        "🎯 القالب: " .. string.format("0x%X", template) .. "\n" ..
        "✅ عدد النتائج للتبديل: " .. #pr .. "\n" ..
        "📋 عدد القيم لكل نتيجة: " .. VALUE_COUNT .. "\n" ..
        "📍 النطاق: من -0xE8 إلى +0x78\n\n" ..
        "❌ لا يمكن التراجع!",
        "✅ نعم، طبّق", "❌ إلغاء"
    ) ~= 1 then
        gg.setVisible(true)
        gg.toast("❌ تم الإلغاء")
        return false
    end

    -- ═══════════════════════════════════════════════════════════
    -- [المرحلة 3] كتابة قيم القالب على كل النتائج (بدون تحقق)
    --   ⚠️ التصحيح: T.address بدلاً من T
    -- ═══════════════════════════════════════════════════════════
    local mods = {}
    local written = 0
    for _, T in ipairs(pr) do
        local base = T.address
        if base ~= template then
            for k = 0, VALUE_COUNT - 1 do
                table.insert(mods, {
                    address = base + OFFSET_START + k * 4,
                    flags   = gg.TYPE_DWORD,
                    value   = templateValues[k + 1]
                })
            end
            written = written + 1
        end
    end

    gg.setValues(mods)
    gg.setVisible(true)
    gg.alert("✅ تم نسخ القيم من القالب وتبديلها على " .. written .. " نتيجة بنجاح")
    return true
end

-- ═══════════════════════════════════════════════════════════
-- ⚡ تنفيذ مهام السباق مباشر (تجميد الصناديق المطابقة)
-- ═══════════════════════════════════════════════════════════
local function applyMoneyValues()
    gg.setVisible(false)
    gg.clearResults()
    gg.searchNumber("-216", gg.TYPE_DWORD)
    local c = gg.getResultsCount()
    if c == 0 then
        gg.toast("❌ لا نتائج")
        gg.clearResults()
        gg.setVisible(true)
        return false
    end
    local r = gg.getResults(c)
    gg.clearResults()

    local cl = {}
    for _, x in ipairs(r) do
        table.insert(cl, {address = x.address + 0x8, flags = gg.TYPE_DWORD})
    end
    local cv = gg.getValues(cl)
    local va
    for i, v in ipairs(cv) do
        if v.value == 328 then
            va = r[i].address
            break
        end
    end
    if not va then
        gg.setVisible(true)
        gg.alert("❌ لا نتيجة صحيحة")
        return false
    end

    gg.loadResults({{address = va, flags = gg.TYPE_QWORD}})
    gg.searchPointer(0)
    local pr = gg.getResults(gg.getResultsCount())
    if #pr == 0 then
        gg.setVisible(true)
        gg.alert("❌ لا نتائج")
        gg.clearResults()
        return false
    end
    gg.clearResults()

    -- ═══════════════════════════════════════════════════════════
    -- [المرحلة 1] إيجاد القالب (Template)
    --   الشرط: -0xC8 == 1768907534  AND  -0xD8 ∈ [65547..65553]
    --   أول نتيجة تحقق الشرطين = مصدر القيم
    -- ═══════════════════════════════════════════════════════════
    local tplChecks = {}
    for _, x in ipairs(pr) do
        table.insert(tplChecks, {address = x.address - 0xC8, flags = gg.TYPE_DWORD})
        table.insert(tplChecks, {address = x.address - 0xD8, flags = gg.TYPE_DWORD})
    end
    local tplVals = gg.getValues(tplChecks)

    local template = nil
    for i = 1, #pr do
        local c8 = tplVals[(i - 1) * 2 + 1].value
        local d8 = tplVals[(i - 1) * 2 + 2].value
        if c8 == 1768907534 and d8 >= 65547 and d8 <= 65555 then
            template = pr[i].address
            break
        end
    end

    if not template then
        gg.setVisible(true)
        gg.alert("❌ لم يتم العثور على النتيجة المصدر (القالب)")
        return false
    end

    -- ═══════════════════════════════════════════════════════════
    -- [المرحلة 2] نسخ قيم القالب من -0xE8 إلى +0x78  (89 قيمة)
    -- ═══════════════════════════════════════════════════════════
    local OFFSET_START = -0xE8
    local OFFSET_END   = 0x14C
    local VALUE_COUNT  = (OFFSET_END - OFFSET_START) / 4 + 1   -- = 89

    local copyList = {}
    for k = 0, VALUE_COUNT - 1 do
        table.insert(copyList, {
            address = template + OFFSET_START + k * 4,
            flags   = gg.TYPE_DWORD
        })
    end
    local copied = gg.getValues(copyList)

    local templateValues = {}
    for i = 1, #copied do
        templateValues[i] = copied[i].value
    end

    -- ═══════════════════════════════════════════════════════════
    -- [المرحلة 3] التحقق من نتائج التبديل (مجموعة مختلفة!)
    --   الشرط: -0xD8 == 65537
    -- ═══════════════════════════════════════════════════════════
    local swapChecks = {}
    for _, x in ipairs(pr) do
        table.insert(swapChecks, {address = x.address - 0xD8, flags = gg.TYPE_DWORD})
    end
    local swapVals = gg.getValues(swapChecks)

    local targets = {}
    for i = 1, #pr do
        if swapVals[i].value == 65537 then
            table.insert(targets, pr[i].address)
        end
    end

    if #targets == 0 then
        gg.setVisible(true)
        gg.alert("❌ لا توجد نتائج صالحة للتبديل (-0xD8 == 65537)")
        return false
    end

    -- ⚠️ تأكيد
    if gg.alert(
    
        "✅ عدد نتائج التبديل: " .. #targets .. "\n" ..
        "✅ نعم، طبّق", "❌ إلغاء"
    ) ~= 1 then
        gg.setVisible(true)
        gg.toast("❌ تم الإلغاء")
        return false
    end

    -- ═══════════════════════════════════════════════════════════
    -- [المرحلة 4] كتابة قيم القالب على نتائج التبديل
    -- ═══════════════════════════════════════════════════════════
    local mods = {}
    for _, T in ipairs(targets) do
        for k = 0, VALUE_COUNT - 1 do
            table.insert(mods, {
                address = T + OFFSET_START + k * 4,
                flags   = gg.TYPE_DWORD,
                value   = templateValues[k + 1]
            })
        end
    end

    gg.setValues(mods)
    gg.setVisible(true)
    gg.alert("✅ تم نسخ القيم من القالب وتبديلها على " .. #targets .. " نتيجة بنجاح")
    return true
end


local function executeMissionsDirect12()
    gg.setVisible(false); gg.clearResults()

    -- 🔸 البحث الصامت عن صندوق الهدية 29
    gg.searchNumber("1970225964", gg.TYPE_DWORD)   -- رقم الهدية 29
    local results = gg.getResults(1000)
    local foundBox = nil

    if #results > 0 then
        for _, v in ipairs(results) do
            local check = gg.getValues({
                {address = v.address + 0x1B0, flags = gg.TYPE_DWORD},
                {address = v.address + 0x1BC, flags = gg.TYPE_DWORD}
            })
            if check[1].value == 29 and (check[2].value == 1 or check[2].value == 2) then
                foundBox = v.address; break
            end
        end
    end
    gg.clearResults()

    if not foundBox then
        gg.alert("⚠️ تعذّر إتمام العملية\n\nتأكد من فتح اللعبة ثم حاول مجدداً")
        return false
    end

    -- 🔸 تحديث العناوين بصمت (بدون إشعارات)
    savedData.boxAddress       = foundBox
    savedData.monitorAddress1  = foundBox - 0x18
    savedData.monitorAddress2  = foundBox + 0x1BC
    savedData.replaceAddresses = {
        foundBox + 0x1C0, foundBox + 0x1C4, foundBox + 0x1C8,
        foundBox + 0x1CC, foundBox + 0x1D0, foundBox + 0x1D4
    }
    savedData.boxType    = 29
    savedData.isUpdated  = true

    -- 🔸 إعادة الضبط الأولية بصمت
    gg.setValues({
        {address = foundBox + 0x1D8, flags = gg.TYPE_DWORD, value = 0},
        {address = foundBox + 0x1DC, flags = gg.TYPE_DWORD, value = 1}
    })


    local zeros = {596655, 12266599, 6966555, 98522556, 9963365, 9952225}
    if not applyItem(zeros, 1) then
        gg.alert("⚠️ تعذّر إتمام العملية\n\nتأكد من فتح اللعبة ثم حاول مجدداً")
        return false
    end


    setMonitor2(2)
    lastMonitor1 = getMonitor1()

    gg.alert("✅ تم تنفيذ المهام بنجاح", "حسناً")
    return true
end

local function executeMissionsDirect()
    gg.setVisible(false)
    gg.clearResults()

    -- ═══════════════════════════════════════════════════════════
    -- 1) إشعار ترحيبي خيالي — أخذ مهمة وحذفها
    -- ═══════════════════════════════════════════════════════════
    local ready = gg.alert(
        "✨✦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━✦✨\n" ..
        "     🚤  وضـع السبـاق المبـاشـر  🚤\n" ..
        "✨✦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━✦✨\n\n" ..
        "🌟 أخي المستخدم الكريم 🌟\n\n" ..
        "📌 قبل أن نبدأ الرحلة، تأكد من:\n\n" ..
        "  1️⃣ دخولك إلى قسم السباق 🚤\n" ..
        "  2️⃣ أخذ مهمة واحدة من المهام\n" ..
        "💡 لماذا الحذف؟ لأن المهام لا تُحتسب\n" ..
        "   إلا بعد حذف مهمة واحدة على الأقل\n\n" ..
        "✨✦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━✦✨\n\n" ..
        "🚀 هل أنت جاهز للانطلاق؟",
        "🚀 نعم، هيّا بنا!", "❌ إلغاء"
    )
    if ready ~= 1 then return end

    -- ═══════════════════════════════════════════════════════════
    -- 2) التأكد من وجود cityMissionValue
    -- ═══════════════════════════════════════════════════════════
    if not cityMissionValue then
        gg.toast("🔍 جاري استخراج قيمة المدينة...")
        local ok, v = extractCityValueFromMission()
        if not ok or not v then
            gg.alert("⚠️ فشل في استخراج قيمة المدينة\n\nتأكد من الاتصال بالإنترنت")
            return false
        end
        cityMissionValue = v
        saveCityValue(v)
    end

    -- ═══════════════════════════════════════════════════════════
    -- 3) البحث الأولي باستخدام cityMissionValue
    -- ═══════════════════════════════════════════════════════════
    gg.toast("🔎 البحث الأولي...")
    gg.searchNumber(cityMissionValue, gg.TYPE_DWORD)
    local allResults = gg.getResults(5000)
    gg.clearResults()

    -- ═══════════════════════════════════════════════════════════
    -- 4) لا نتائج — خيارات المستخدم
    -- ═══════════════════════════════════════════════════════════
    if #allResults == 0 then
        local choice = gg.choice({
            "✅ نعم، اكتشف القيمة من جديد",
            "🔙 لا، تحقق من القيم الحالية",
            "❌ إلغاء العملية"
        }, nil,
            "⚠️ لم نجد قيمة البحث الرئيسية\n\n" ..
            "الأسباب المحتملة:\n" ..
            "  📡 أنك غير متصل بالإنترنت\n" ..
            "  ⚙️ قيم اللعبة عندك غير مضبوطة\n" ..
            "  🚤 قسم السباق غير مفتوح\n\n" ..
            "هل تريد اكتشاف قيمة البحث من جديد؟")

        if choice == 1 then
            gg.toast("🔍 استخراج قيمة جديدة...")
            local ok, v = extractCityValueFromMission()
            if not ok or not v then
                gg.alert("⚠️ فشل في استخراج القيمة الجديدة\n\nحاول مجدداً")
                return false
            end
            cityMissionValue = v
            saveCityValue(v)

            gg.searchNumber(cityMissionValue, gg.TYPE_DWORD)
            allResults = gg.getResults(5000)
            gg.clearResults()

            if #allResults == 0 then
                gg.alert(
                    "⚠️ لا توجد نتائج حتى بعد إعادة الاستخراج\n\n" ..
                    "تأكد من فتح قسم السباق ثم حاول مجدداً"
                )
                return false
            end
        else
            gg.alert(
                "⚠️ لا يمكن المتابعة بدون نتائج بحث\n\n" ..
                "افتح قسم السباق وحاول مجدداً"
            )
            return false
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- 5) التحقق الجماعي دفعة واحدة:
    --    +0x88 == 1
    --    +0xA4 في [500, 600]
    --    +0x98 في [500, 600]
    --    قراءة +0xC0 (نقاط مأخوذة) و +0xC4 (منفذة)
    -- ═══════════════════════════════════════════════════════════
    gg.toast("🔎 التحقق من " .. #allResults .. " نتيجة...")

    local checkList = {}
    for _, r in ipairs(allResults) do
        table.insert(checkList, {address = r.address + 0x88, flags = gg.TYPE_DWORD})
        table.insert(checkList, {address = r.address + 0xA4, flags = gg.TYPE_DWORD})
        table.insert(checkList, {address = r.address + 0x98, flags = gg.TYPE_DWORD})
        table.insert(checkList, {address = r.address + 0xC0, flags = gg.TYPE_DWORD})
        table.insert(checkList, {address = r.address + 0xC4, flags = gg.TYPE_DWORD})
    end
    local vals = gg.getValues(checkList)

    local validCount = 0
    local pointsTaken = nil
    local missionsExecuted = nil

    for i = 1, #allResults do
        local base = (i - 1) * 5 + 1
        local v88 = vals[base].value
        local vA4 = vals[base + 1].value
        local v98 = vals[base + 2].value
        if v88 == 1 and vA4 >= 500 and vA4 <= 600 and v98 >= 500 and v98 <= 600 then
            validCount = validCount + 1
            if not pointsTaken then
                pointsTaken      = vals[base + 3].value  -- +0xC0
                missionsExecuted = vals[base + 4].value  -- +0xC4
            end
        end
    end

    if validCount == 0 then
        gg.alert(
            "⚠️ لم نجد أي مهام صالحة\n\n" ..
            "تأكد من:\n" ..
            "  1️⃣ أخذ مهمة واحدة وحذفها ✅\n" ..
            "  2️⃣ فتح قسم السباق 🚤\n" ..
            "  3️⃣ الاتصال بالإنترنت 📡"
        )
        return false
    end

    -- ═══════════════════════════════════════════════════════════
    -- 6) تحديد "آخر مغادرة" (950 → 1010 أو أكثر)
    -- ═══════════════════════════════════════════════════════════
    local isLastDeparture = (validCount >= 950)

    local statsMsg =
        "✨✦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━✦✨\n" ..
        "        📊 إحصائيات المهام\n" ..
        "✨✦━━━━━━━━━━━━━━━━━━━━━━━━━━━━━✦✨\n\n" ..
        "✅ عدد المهام الموجودة: "   .. validCount .. "\n" ..
        "🎯 نقاط المهام المأخوذة: "  .. tostring(pointsTaken or "؟") .. "\n" ..
        "🏁 المهام المنفذة: "        .. tostring(missionsExecuted or "؟") .. "\n"

    if isLastDeparture then
        -- 🚨 آخر مغادرة — تحذير + ملاحظة كاملة + عدم استدعاء دالة الإضافة
        gg.alert(
            statsMsg .. "\n" ..
            "╔══════════════════════════════════╗\n" ..
            "║  🚨 تحذير: هذه آخر مغادرة! 🚨   ║\n" ..
            "╚══════════════════════════════════╝\n\n" ..
            "🏃 غادر سريعاً قبل الحظر!\n\n" ..
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
            "📌 ملاحظات مهمة:\n\n" ..
            "🔹 يجب أن يكون لديك دعوة مسبقاً\n" ..
            "🔹 تمت إضافة المهام إلى صناديق التصريح\n" ..
            "🔹 اخرج من التعاون وادخل إليه\n" ..
            "    خلال أقل من دقيقة ⏱️\n" ..
            "🔹 عند الانضمام، تحقق من تغيّر أيقونة السباق\n" ..
            "    إلى اللون الذهبي 🏆\n" ..
            "🔹 ادخل على التصريح لاستلام المهام مجدداً\n" ..
            "🔹 إذا توقفت اللعبة، أعد تشغيلها وشغّل GG\n" ..
            "    وواصل العمل\n\n" ..
            "🍀 نتمنى لك التوفيق والنجاح 🍀",
            "✔️ فهمت، سأغادر الآن"
        )
        return true
    end

    -- ═══════════════════════════════════════════════════════════
    -- 7) الحالة الطبيعية — تأكيد ثم استدعاء دالة إضافة المهام
    -- ═══════════════════════════════════════════════════════════
    local confirm = gg.alert(
        statsMsg .. "\n" ..
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
        "هل تريد إضافة هذه المهام إلى صناديق التصريح؟",
        "✅ نعم، أضف المهام", "❌ إلغاء"
    )
    if confirm ~= 1 then
        gg.toast("❌ تم الإلغاء")
        return false
    end

    gg.toast("📦 جاري إضافة المهام إلى الصناديق...")
    executeMissionsDirect12()   -- 🎯 "دالة إضافة المهام"

    -- ═══════════════════════════════════════════════════════════
    -- 8) الملاحظة النهائية بعد الإضافة الناجحة
    -- ═══════════════════════════════════════════════════════════
    gg.alert(
        "تمت اضافة المهام الى صناديق التصريح بنجاح!\n\n" ..
        "تاكد ان لديك دعوه من قبل او اطلب من أصدقائك طلب دعوه باقرب وفت\n\n" ..
        "  1️⃣ اخرج من التعاون وادخل إليه\n" ..
        "      خلال أقل من دقيقة ⏱️\n" ..
        "  2️⃣ عند الانضمام، تحقق من تغيّر أيقونة السباق\n" ..
        "      إلى اللون الذهبي 🏆\n" ..
        "  3️⃣ ادخل على التصريح لاستلام المهام مجدداً\n" ..
        "  4️⃣ إذا توقفت اللعبة، أعد تشغيلها وشغّل GG\n" ..
        "      وواصل العمل\n\n" ..
        "🍀 نتمنى لك التوفيق والنجاح 🍀",
        "حسناً"
    )

    return true
end




-- ═══════════════════════════════════════════════════════════
-- قائمة السباق (7 خيارات)
-- ═══════════════════════════════════════════════════════════
showRaceMenu = function()
    currentMenuFn = showRaceMenu
    local items = {
        "↩️ رجـــــــــــــــــــــــــــــــــوع",
        "🎯 تهيئـــة المهـــام وتنفيذهـــا",
        "⚡ استلام المهام من التصريح ",
        " تنفيـــذ مهـــام السبـــاق بالطريقة التقليديه ",
        "💰 تبـــديـــل كـــل الصنـــاديـــق الـــى نقـــود",
        "⚙️ حدث قيم المدينه عند الحاجه ",
        "🔧 تنفيـــذ المهـــام بطريقـــة الأداة (قريبـــاً)",
        "↩️ رجـــــــــــــــــــــــــــــــــوع",
        "❌ الخـــــــروج"
    }
    local c = gg.choice(items, nil, "🚤 قسم السباق")
    if not c then return end
    if c == 1 or c == 9 then
        currentMenuFn = showMainMenu
        return showMainMenu()
    end
    if c == 2 then
        setupAndExecuteMissions()
    elseif c == 3 then
        executeMissionsDirect()                    -- 🆕
    elseif c == 4 then
        executeRaceMissionsDirect()
    elseif c == 5 then
   applyMoneyValues()    
    elseif c == 6 then
        gg.alert("⏳ طور التنفيذ\n\nسيتم نشرها قريباً إن شاء الله")
    elseif c == 7 then
        gg.alert("⏳ في طور التنفيذ\n\nسيتم نشرها في الأيام القليلة القادمة إن شاء الله")
    elseif c == 8 then
        gg.toast("👋 مع السلامة ✨")
        os.exit()
    end
end




local stickersList = expandMultiTemplate({

    {
        template = {1869440276, 1935632746, "?", 0, 0, 0},
        items = {
            {name = "🦆 بطة البوسه", v = 3486324}, {name = "🦆 بطة العضلات", v = 3486068}, {name = "🦆 بطة هالوين بوسه", v = 3290228}, {name = "🦆 بطة المصاص", v = 3354992},
            {name = "🦆 بطة العابره", v = 3420784}, {name = "🦆 بطة المتنكره", v = 3355508}, {name = "🦆 البطة النائمه", v = 3748208}, {name = "🦆 البطة المتنكره", v = 3682672},
            {name = "🦆 بطة الهديه", v = 3744112}, {name = "🦆 بطة تنعس", v = 3158384}, {name = "🐝 النحلة الراقصه", v = 3223924}, {name = "🐝 نحلة الكريسماس", v = 3551604},
            {name = "🐝 النحلة الماهره", v = 3551860}, {name = "🐝 نحلة عيد الفصح", v = 3158900}, {name = "🐝 نحلة هالوين", v = 3355764}, {name = "🐝 النحله النائمه", v = 3617652},
            {name = "🐔 الفرخه المشعوذه", v = 3422068}, {name = "🐔 الفرخه في استراحه", v = 3159924}, {name = "🐔 الفرخه الساحره", v = 3158388}, {name = "🐔 فرخه تتزلج على الجليد", v = 3682676},
            {name = "🐔 الفرخه الخبازه", v = 3420788}, {name = "🐔 فرخه تسمع الموسيقى", v = 3683188}, {name = "🐔 فرخه تودع", v = 3224692}, {name = "🐔 فرخه رياضيه", v = 3683444},
            {name = "🐔 الفرخه الجنيه", v = 3224948}, {name = "🐔 الفرخه غمزه", v = 3421556}, {name = "🐔 فرخه الحفل", v = 3683700}, {name = "🐔 فرخة الاستعراض", v = 3290740},
            {name = "🐔 فرخه تعزف على اله موسيقيه", v = 3487348}, {name = "🐔 فرخه صينيه", v = 3684212}, {name = "🐄 بقرة القراصنه", v = 3487604}, {name = "🐄 البقرة على دراجه", v = 3225460},
            {name = "🐄 بقرة تحمل سلة الخضار", v = 3354996}, {name = "🐄 بقرة في الفضاء", v = 3289716}, {name = "🐄 البقرة المغنيه", v = 3224436}, {name = "🐄 بقرة تشغل النار", v = 3552116},
            {name = "🐄 بقرة مصاص الدماء تاكل فوشار", v = 3159156}, {name = "🐄 بقرة الكريسماس", v = 3486836}, {name = "🐄 بقرة القلوب", v = 3617908}, {name = "🐄 بقرة على المريخ", v = 3159412},
            {name = "🐄 بقرة تحضر الكيك", v = 3487092}, {name = "🐄 بقرة مصاص الدماء خفاش", v = 3552628}, {name = "🐄 بقرة على لوح تزلج", v = 3749236}, {name = "🐄 بقرة عيد الفصح", v = 3356276},
            {name = "🐄 بقرة اعلاميه تصور", v = 3552884}, {name = "🐄 البقره الملكه", v = 3683956}, {name = "🐄 بقرة تشرب الشاي", v = 3618676}, {name = "🐄 بقرة تعليم الموسيقى", v = 3749748},
            {name = "🐑 خروف الهارب", v = 3553140}, {name = "🐑 الخروف المصري", v = 3422068}, {name = "🐑 خروف الهديه", v = 3290996}, {name = "🐑 خروف بالثلج", v = 3617140},
            {name = "🐑 خروف العازف", v = 3617396}, {name = "🐑 خروف يضرب التلفاز", v = 3486580}, {name = "🐑 خروف مقلب التنين", v = 3552372}, {name = "🐑 خروف مقلب الذئب", v = 3289460},
            {name = "🐑 خروف بلباس الارنب", v = 3748980}, {name = "🐑 خروف ملك", v = 3290484}, {name = "🐑 خروف المحقق", v = 3356020}, {name = "🐑 خروف الرمايه", v = 3618164},
            {name = "🐑 خروف على شكل مهرج", v = 3159668}, {name = "🐑 خروف يعزف على الجيتار", v = 3421812}, {name = "🐑 خروف الفارس", v = 3618420}, {name = "🐑 الخروف بوسه", v = 3749492},
            {name = "🐑 خروف تسريحة الشعر", v = 3160180}, {name = "🦭 كلب البحر مصباح علاء الدين", v = 3682932}, {name = "🦭 كلب البحر المطبل", v = 3289972}, {name = "🦭 كلب البحر على المسرح", v = 3421300},
            {name = "🦭 كلب البحر الساحر", v = 3416432}, {name = "🦭 كلب البحر يرقص بكرشه", v = 3289968}, {name = "🦭 كلب البحر الشرير 2", v = 3289712}, {name = "🐖 خنزير اوكيتو", v = 3420532},
            {name = "🐖 خنزير على صاروخ", v = 3355252}, {name = "🐖 خنزير على القارب", v = 3421044}, {name = "🐖 خنزيره تفوز بالجائزه", v = 3748724}, {name = "🐖 خنزير يشرب القهوه", v = 3225204},
            {name = "🐖 خنزير المراقبه", v = 3158900}, {name = "🐖 خنزير متزلج", v = 3482480}, {name = "🐖 خنزير بقبعه", v = 3486320}, {name = "🐖 خنزير بنظاره", v = 3223920},
            {name = "🐖 خنزير ياباني", v = 3158640}, {name = "🐿️ سنجاب تحيه", v = 3421300},
        }
    },
    {
        template = {1869440274, 1935632746, "?", 0, 0, 0},
        items = {
            {name = "🦆 بطة السيلفي", v = 14704}, {name = "🦆 بطة القراصنه تطلق النار", v = 12660}, {name = "🦆 بطة تعلن الاستسلام", v = 14196}, {name = "🐝 النحله الضاحكه", v = 13936},
            {name = "🐝 النحله العازفه", v = 13940}, {name = "🐔 فرخة اوكيتو وغمزه", v = 13424}, {name = "🐑 خروف مفاجأه", v = 12656}, {name = "🐑 خروف يقدم العصير", v = 13428},
            {name = "🦭 كلب البحر شيطان", v = 13168}, {name = "🦭 كلب البحر يضرب راسه", v = 14448}, {name = "🦭 كلب البحر يلعب بالنقود", v = 14708}, {name = "🐖 خنزير يشم الزهور", v = 13680},
            {name = "🐖 خنزير يلعب بالحبل", v = 14452}, {name = "🐖 خنزير النظاره", v = 13172}, {name = "🐓 ديك لايك", v = 3421296}, {name = "🐄 بقرة بوسات", v = 12912},
            {name = "🐄 بقرة في السينمه تاكل الفوشار", v = 14192}, {name = "🐄 بقرة ببرميل قراصنه", v = 3158644}, {name = "🐄 بقرة بوسة قلوب 2", v = 3420784},
        }
    },
    {
        template = {1869440272, 1985960298, "?", 0, 0, 0},
        items = {
            {name = "🦆 بطتين الحب", v = 50}, {name = "🦭 كلب البحر يحضن قلب", v = 51},
        }
    }
})


local picturesList = expandTemplate({1635148044, "?", 0, 0, 0, 0}, {
    {name = "📸 صوره بروفايل 1 عام 📸", v = 3748145}, {name = "📸 صوره بروفايل 2 عام 📸", v = 3158577}, {name = "📸 صوره بروفايل 3 عام 📸", v = 3224113}, {name = "📸 صوره بروفايل 4 عام 📸", v = 3289649},
    {name = "📸 صوره بروفايل 5 عام 📸", v = 3355185}, {name = "📸 صوره بروفايل 6 عام 📸", v = 3421489}, {name = "📸 صوره بروفايل 7 عام 📸", v = 3225905}, {name = "📸 صوره بروفايل 8 عام 📸", v = 3748658},
    {name = "📸 صوره بروفايل 9 عام 📸", v = 3225650}, {name = "📸 صوره بروفايل 10 عام 📸", v = 3354931}, {name = "📸 صوره بروفايل 11 عام 📸", v = 3290675}, {name = "📸 حدث الأفعوانية 📸", v = 3684657},
    {name = "📸 مهرجان العلكة 📸", v = 3486258}, {name = "📸 احتفال الذكرى السنوية العاشرة 📸", v = 3289395}, {name = "📸 ببغاءآخر 📸", v = 3749938}, {name = "📸 ببغاء بعجلة 📸", v = 3355186},
    {name = "📸 ببغاء 📸", v = 3617074}, {name = "📸 بطة تلقي التحية 📸", v = 3487537}, {name = "📸 بطة ترتدي معطف 📸", v = 3617331}, {name = "📸 كلب يحمل بخاخ 📸", v = 3422001},
    {name = "📸 كلب فوق رأسه فرخة 📸", v = 3420211}, {name = "📸 أرنبة ترسم على البيض 📸", v = 3551538}, {name = "📸 أرنبة تضحك 📸", v = 3224370}, {name = "📸 حمار يضحك 📸", v = 3289906},
    {name = "📸 حمامة الحب 📸", v = 3290418}, {name = "📸 خروف عيد الميلاد 📸", v = 3355953}, {name = "📸 خروف فارس 📸", v = 3617843}, {name = "📸 خروف يحمل خيزرانة 📸", v = 3684145},
    {name = "📸 خروف الديسكو 📸", v = 3486515}, {name = "📸 خروف أنيق 📸", v = 3158834}, {name = "📸 خروف برازيلي 📸", v = 3551795}, {name = "📸 خروف بالزي الرسمي 📸", v = 3354675},
    {name = "📸 فرخة عاملة 📸", v = 3160113}, {name = "📸 فرخة مسرحية 📸", v = 3684146}, {name = "📸 فرخة تحمل فانوس 📸", v = 3616819}, {name = "📸 فرخة إيرلندية تحمل برسيم 📸", v = 3355443},
    {name = "📸 فرخة صيفية تشرب العصير 📸", v = 3487027}, {name = "📸 فرخة تأكل العنب 📸", v = 3748659}, {name = "📸 بقرة بالزي الرسمي 📸", v = 3224627}, {name = "📸 بقرة عيد الفصح 📸", v = 3420979},
    {name = "📸 بقرة حمى الحب 📸", v = 3618866}, {name = "📸 بقرة دراكولا 📸", v = 3159090}, {name = "📸 بقرة الشتاء الرياضي 📸", v = 3486259}, {name = "📸 بقرة أطلانتس 📸", v = 3159347},
    {name = "📸 بقرة مهرجان العلكة 📸", v = 3159601}, {name = "📸 خنزير يأكل 🍭 📸", v = 3551794}, {name = "📸 خنزير يشرب العصير 📸", v = 3355442}, {name = "📸 خنزير الفوانيس 📸", v = 3158835},
    {name = "📸 صقر 📸", v = 3422258}, {name = "📸 خفاش 🦇 📸", v = 3749169}, {name = "📸 ثعلب يأكل العشب 📸", v = 3553073}, {name = "📸 تمساح صيفي 📸", v = 3356210},
    {name = "📸 غزالة كريسماس 📸", v = 3748401}, {name = "📸 حيوان أليف كريسماس 📸", v = 3158833}, {name = "📸 حيوان أليف يرتدي معطف 📸", v = 3224369}, {name = "📸 حيوان أليف ركب الجليد 📸", v = 3224114},
    {name = "📸 دب رومانسي يعزف 📸", v = 3422002}, {name = "📸 فأر يحمل كيك 📸", v = 3750193}, {name = "📸 دجاجة رياضية 📸", v = 3160370}, {name = "📸 شاب يحمل يقطين 📸", v = 3420467},
    {name = "📸 شاب يحمل ميدالية 📸", v = 3290162}, {name = "📸 شاب احتفال صيني 📸", v = 3684658}, {name = "📸 امرأة قرصانة 📸", v = 3684402}, {name = "📸 امرأة طباخة 📸", v = 3747891},
    {name = "📸 ولد إيطالي يأكل البيتزا 📸", v = 3552307}, {name = "📸 ولد مصاص دماء 📸", v = 3420978}, {name = "📸 ولد الكريسماس 📸", v = 3355698}, {name = "📸 ولد يحمل السمك 📸", v = 3421234},
    {name = "📸 ولد غواص 📸", v = 3289905}, {name = "📸 ولد استكشاف الجزيرة المفقودة 📸", v = 3682355}, {name = "📸 بنت تحمل دمية لطيفة 📸", v = 3289907}, {name = "📸 بنت تشرب العصير 📸", v = 3159091},
    {name = "📸 بنت ترتدي قبعة 📸", v = 3748402}, {name = "📸 بنت تحدي الفضاء 📸", v = 3486770}, {name = "📸 بنت عيد الفصح 📸", v = 3224882}, {name = "📸 بنت المكياج 📸", v = 3422514},
    {name = "📸 بنت رسامة 📸", v = 3618098}, {name = "📸 رجل يحمل القمح 📸", v = 3224626}, {name = "📸 رجل قرصان 📸", v = 3289394}, {name = "📸 رجل رحلة التخييم 📸", v = 3552051},
    {name = "📸 رجل فرنسي 📸", v = 3748914}, {name = "📸 رجل رياضي 📸", v = 3289651}, {name = "📸 ملك عربي 📸", v = 3159346}, {name = "📸 عجوز الديسكو 📸", v = 3224371},
    {name = "📸 عجوز يحمل بطاقات 📸", v = 3159858}, {name = "📸 عجوز أنيقة 📸", v = 3682866}, {name = "📸 ضيف غامض 📸", v = 3683378}, {name = "📸 كائن-فضائي 📸", v = 3552563},
    {name = "📸 قزم يحمل هدية 📸", v = 3354673}, {name = "📸 صورة 1 📸", v = 3552562}, {name = "📸 صورة 2 📸", v = 3749170}, {name = "📸 صورة 3 📸", v = 3290674},
    {name = "📸 صورة 4 📸", v = 3487282}, {name = "📸 صورة 5 📸", v = 3618354}, {name = "📸 صورة 6 📸", v = 3158323}, {name = "📸 صورة 7 📸", v = 3486003},
    {name = "📸 صورة 8 📸", v = 3683890}, {name = "📸 صورة 9 📸", v = 3159602}, {name = "📸 صورة 10 📸", v = 3749426}, {name = "📸 صورة 11 📸", v = 3225394},
    {name = "📸 صورة 12 📸", v = 3290930}, {name = "📸 صورة 13 📸", v = 3356466}, {name = "📸 صورة 14 📸", v = 3487538}, {name = "📸 صورة 15 📸", v = 3553074},
    {name = "📸 صورة 16 📸", v = 3618610}, {name = "📸 صورة 17 📸", v = 3749682}, {name = "📸 صورة 18 📸", v = 3160114}, {name = "📸 صورة 19 📸", v = 3291186},
    {name = "📸 صورة 20 📸", v = 3356722}, {name = "📸 صورة 21 📸", v = 3487794}, {name = "📸 صورة 22 📸", v = 3553330}, {name = "📸 صورة 23 📸", v = 3225906},
    {name = "📸 صورة 24 📸", v = 3291442}, {name = "📸 صورة 25 📸", v = 3356978}, {name = "📸 صورة 26 📸", v = 3488050}, {name = "📸 صورة 27 📸", v = 3553586},
    {name = "📸 صورة 28 📸", v = 3619122}, {name = "📸 صورة 29 📸", v = 3750194}, {name = "📸 صورة 30 📸", v = 3158067}, {name = "📸 صورة 31 📸", v = 3289139},
    {name = "📸 صورة 32 📸", v = 3485747}, {name = "📸 صورة 33 📸", v = 3551283}, {name = "📸 صورة 35 📸", v = 3619378}, {name = "📸 صورة 36 📸", v = 3684914},
    {name = "📸 صورة 37 📸", v = 3750450}, {name = "📸 صورة 38 📸", v = 3158310}, {name = "📸 صورة 39 📸", v = 3225882}, {name = "📸 صورة 40 📸", v = 3291954},
    {name = "📸 صورة 41 📸", v = 3357490}, {name = "📸 صورة 42 📸", v = 3423026}, {name = "📸 صورة 43 📸", v = 3488562}, {name = "📸 صورة 44 📸", v = 3554098},
    {name = "📸 صورة 45 📸", v = 3619634}, {name = "📸 صورة 46 📸", v = 3685170}, {name = "📸 صورة 47 📸", v = 3750706}, {name = "📸 صورة 48 📸", v = 3158566},
    {name = "📸 صورة 49 📸", v = 3226138}, {name = "📸 صورة 50 📸", v = 3292210}, {name = "📸 صورة 51 📸", v = 3357746}, {name = "📸 صورة 52 📸", v = 3423282},
    {name = "📸 صورة 53 📸", v = 3488818}, {name = "📸 صورة 54 📸", v = 3554354}, {name = "📸 صورة 55 📸", v = 3619890}, {name = "📸 صورة 56 📸", v = 3685426},
    {name = "📸 صورة 57 📸", v = 3750962}, {name = "📸 صورة 58 📸", v = 3158822}, {name = "📸 صورة 59 📸", v = 3226394}, {name = "📸 صورة 60 📸", v = 3292466},
    {name = "📸 صورة 61 📸", v = 3358002}, {name = "📸 صورة 62 📸", v = 3423538}, {name = "📸 صورة 63 📸", v = 3489074}, {name = "📸 صورة 64 📸", v = 3554610},
    {name = "📸 صورة 65 📸", v = 3620146}, {name = "📸 صورة 66 📸", v = 3685682}, {name = "📸 صورة 67 📸", v = 3751218}, {name = "📸 صورة 68 📸", v = 3159078},
    {name = "📸 صورة 69 📸", v = 3226650}, {name = "📸 صورة 70 📸", v = 3292722}, {name = "📸 صورة 71 📸", v = 3358258}, {name = "📸 صورة 72 📸", v = 3423794},
    {name = "📸 صورة 73 📸", v = 3489330}, {name = "📸 صورة 74 📸", v = 3554866}, {name = "📸 صورة 75 📸", v = 3620402}, {name = "📸 صورة 76 📸", v = 3685938},
    {name = "📸 صورة 77 📸", v = 3751474}, {name = "📸 صورة 78 📸", v = 3159334}, {name = "📸 صورة 79 📸", v = 3226906}, {name = "📸 صورة 80 📸", v = 3292978},
    {name = "📸 صورة 81 📸", v = 3358514}, {name = "📸 صورة 82 📸", v = 3424050}, {name = "📸 صورة 83 📸", v = 3489586}, {name = "📸 صورة 84 📸", v = 3555122},
    {name = "📸 صورة 85 📸", v = 3620658}, {name = "📸 صورة 86 📸", v = 3686194}, {name = "📸 صورة 87 📸", v = 3751730}, {name = "📸 صورة 88 📸", v = 3159590},
    {name = "📸 صورة 89 📸", v = 3227162}, {name = "📸 صورة 90 📸", v = 3293234}, {name = "📸 صورة 91 📸", v = 3358770}, {name = "📸 صورة 92 📸", v = 3424306},
    {name = "📸 صورة 93 📸", v = 3489842}, {name = "📸 صورة 94 📸", v = 3555378}, {name = "📸 صورة 95 📸", v = 3620914}, {name = "📸 صورة 96 📸", v = 3686450},
    {name = "📸 صورة 97 📸", v = 3751986}, {name = "📸 صورة 98 📸", v = 3159846}, {name = "📸 صورة 99 📸", v = 3227418}, {name = "📸 صورة 100 📸", v = 3293490},
    {name = "📸 صورة 101 📸", v = 3359026}, {name = "📸 صورة 102 📸", v = 3424562}, {name = "📸 صورة 103 📸", v = 3490098}, {name = "📸 صورة 104 📸", v = 3555634},
    {name = "📸 صورة 105 📸", v = 3621170}, {name = "📸 صورة 106 📸", v = 3686706}, {name = "📸 صورة 107 📸", v = 3752242}, {name = "📸 صورة 108 📸", v = 3160102},
    {name = "📸 صورة 109 📸", v = 3227674}, {name = "📸 صورة 110 📸", v = 3293746}, {name = "📸 صورة 111 📸", v = 3359282}, {name = "📸 صورة 112 📸", v = 3424818},
    {name = "📸 صورة 113 📸", v = 3490354}, {name = "📸 صورة 114 📸", v = 3555890}, {name = "📸 صورة 115 📸", v = 3621426}, {name = "📸 صورة 116 📸", v = 3686962},
    {name = "📸 صورة 117 📸", v = 3752498}, {name = "📸 صورة 118 📸", v = 3160358}, {name = "📸 صورة 119 📸", v = 3227930}, {name = "📸 صورة 120 📸", v = 3294002},
    {name = "📸 صورة 121 📸", v = 3359538}, {name = "📸 صورة 122 📸", v = 3425074}, {name = "📸 صورة 123 📸", v = 3490610}, {name = "📸 صورة 124 📸", v = 3556146},
    {name = "📸 صورة 125 📸", v = 3621682}, {name = "📸 صورة 126 📸", v = 3687218}, {name = "📸 صورة 127 📸", v = 3752754}, {name = "📸 صورة 128 📸", v = 3160614},
    {name = "📸 صورة 129 📸", v = 3228186}, {name = "📸 صورة 130 📸", v = 3294258}, {name = "📸 صورة 131 📸", v = 3359794}, {name = "📸 صورة 132 📸", v = 3425330},
    {name = "📸 صورة 133 📸", v = 3490866}, {name = "📸 صورة 134 📸", v = 3556402}, {name = "📸 صورة 135 📸", v = 3225395}, {name = "📸 صورة 136 📸", v = 3290931},
    {name = "📸 صورة 137 📸", v = 3356467}, {name = "📸 صورة 138 📸", v = 3422003}, {name = "📸 صورة 139 📸", v = 3487539}, {name = "📸 صورة 140 📸", v = 3553075},
    {name = "📸 صورة 141 📸", v = 3618611}, {name = "📸 صورة 142 📸", v = 3684147}, {name = "📸 صورة 143 📸", v = 3225651}, {name = "📸 صورة 144 📸", v = 3356723},
    {name = "📸 صورة 145 📸", v = 3422259}, {name = "📸 صورة 146 📸", v = 3487795}, {name = "📸 صورة 147 📸", v = 3553331}, {name = "📸 صورة 148 📸", v = 3618867},
    {name = "📸 صورة 149 📸", v = 3684403}, {name = "📸 صورة 150 📸", v = 3749939}, {name = "📸 صورة 151 📸", v = 3160371}, {name = "📸 صورة 152 📸", v = 3225907},
    {name = "📸 صورة 153 📸", v = 3422515}, {name = "📸 صورة 154 📸", v = 3488051}, {name = "📸 صورة 155 📸", v = 3553587}, {name = "📸 صورة 156 📸", v = 3619123},
    {name = "📸 صورة 157 📸", v = 3684659}, {name = "📸 إضافة 001 📸", v = 3619378}, {name = "📸 إضافة 002 📸", v = 3684914}, {name = "📸 إضافة 003 📸", v = 3750450},
    {name = "📸 إضافة 004 📸", v = 3158310}, {name = "📸 إضافة 005 📸", v = 3225882}, {name = "📸 إضافة 006 📸", v = 3291954}, {name = "📸 إضافة 007 📸", v = 3357490},
    {name = "📸 إضافة 008 📸", v = 3423026}, {name = "📸 إضافة 009 📸", v = 3488562}, {name = "📸 إضافة 010 📸", v = 3554098}, {name = "📸 إضافة 011 📸", v = 3619634},
    {name = "📸 إضافة 012 📸", v = 3685170}, {name = "📸 إضافة 013 📸", v = 3750706}, {name = "📸 إضافة 014 📸", v = 3158566}, {name = "📸 إضافة 015 📸", v = 3226138},
    {name = "📸 إضافة 016 📸", v = 3292210}, {name = "📸 إضافة 017 📸", v = 3357746}, {name = "📸 إضافة 018 📸", v = 3423282}, {name = "📸 إضافة 019 📸", v = 3488818},
    {name = "📸 إضافة 020 📸", v = 3554354}, {name = "📸 إضافة 021 📸", v = 3619890}, {name = "📸 إضافة 022 📸", v = 3685426}, {name = "📸 إضافة 023 📸", v = 3750962},
    {name = "📸 إضافة 024 📸", v = 3158822}, {name = "📸 إضافة 025 📸", v = 3226394}, {name = "📸 إضافة 026 📸", v = 3292466}, {name = "📸 إضافة 027 📸", v = 3358002},
    {name = "📸 إضافة 028 📸", v = 3423538}, {name = "📸 إضافة 029 📸", v = 3489074}, {name = "📸 إضافة 030 📸", v = 3554610}, {name = "📸 إضافة 031 📸", v = 3620146},
    {name = "📸 إضافة 032 📸", v = 3685682}, {name = "📸 إضافة 033 📸", v = 3751218}, {name = "📸 إضافة 034 📸", v = 3159078}, {name = "📸 إضافة 035 📸", v = 3226650},
    {name = "📸 إضافة 036 📸", v = 3292722}, {name = "📸 إضافة 037 📸", v = 3358258}, {name = "📸 إضافة 038 📸", v = 3423794}, {name = "📸 إضافة 039 📸", v = 3489330},
    {name = "📸 إضافة 040 📸", v = 3554866}, {name = "📸 إضافة 041 📸", v = 3620402}, {name = "📸 إضافة 042 📸", v = 3685938}, {name = "📸 إضافة 043 📸", v = 3751474},
    {name = "📸 إضافة 044 📸", v = 3159334}, {name = "📸 إضافة 045 📸", v = 3226906}, {name = "📸 إضافة 046 📸", v = 3292978}, {name = "📸 إضافة 047 📸", v = 3358514},
    {name = "📸 إضافة 048 📸", v = 3424050}, {name = "📸 إضافة 049 📸", v = 3489586}, {name = "📸 إضافة 050 📸", v = 3555122}, {name = "📸 إضافة 051 📸", v = 3620658},
    {name = "📸 إضافة 052 📸", v = 3686194}, {name = "📸 إضافة 053 📸", v = 3751730}, {name = "📸 إضافة 054 📸", v = 3159590}, {name = "📸 إضافة 055 📸", v = 3227162},
    {name = "📸 إضافة 056 📸", v = 3293234}, {name = "📸 إضافة 057 📸", v = 3358770}, {name = "📸 إضافة 058 📸", v = 3424306}, {name = "📸 إضافة 059 📸", v = 3489842},
    {name = "📸 إضافة 060 📸", v = 3555378}, {name = "📸 إضافة 061 📸", v = 3620914}, {name = "📸 إضافة 062 📸", v = 3686450}, {name = "📸 إضافة 063 📸", v = 3751986},
    {name = "📸 إضافة 064 📸", v = 3159846}, {name = "📸 إضافة 065 📸", v = 3227418}, {name = "📸 إضافة 066 📸", v = 3293490}, {name = "📸 إضافة 067 📸", v = 3359026},
    {name = "📸 إضافة 068 📸", v = 3424562}, {name = "📸 إضافة 069 📸", v = 3490098}, {name = "📸 إضافة 070 📸", v = 3555634}, {name = "📸 إضافة 071 📸", v = 3621170},
    {name = "📸 إضافة 072 📸", v = 3686706}, {name = "📸 إضافة 073 📸", v = 3752242}, {name = "📸 إضافة 074 📸", v = 3160102}, {name = "📸 إضافة 075 📸", v = 3227674},
    {name = "📸 إضافة 076 📸", v = 3293746}, {name = "📸 إضافة 077 📸", v = 3359282}, {name = "📸 إضافة 078 📸", v = 3424818}, {name = "📸 إضافة 079 📸", v = 3490354},
    {name = "📸 إضافة 080 📸", v = 3555890}, {name = "📸 إضافة 081 📸", v = 3621426}, {name = "📸 إضافة 082 📸", v = 3686962}, {name = "📸 إضافة 083 📸", v = 3752498},
    {name = "📸 إضافة 084 📸", v = 3160358}, {name = "📸 إضافة 085 📸", v = 3227930}, {name = "📸 إضافة 086 📸", v = 3294002}, {name = "📸 إضافة 087 📸", v = 3359538},
    {name = "📸 إضافة 088 📸", v = 3425074}, {name = "📸 إضافة 089 📸", v = 3490610}, {name = "📸 إضافة 090 📸", v = 3556146}, {name = "📸 إضافة 091 📸", v = 3621682},
    {name = "📸 إضافة 092 📸", v = 3687218}, {name = "📸 إضافة 093 📸", v = 3752754}, {name = "📸 إضافة 094 📸", v = 3160614}, {name = "📸 إضافة 095 📸", v = 3228186},
    {name = "📸 إضافة 096 📸", v = 3294258}, {name = "📸 إضافة 097 📸", v = 3359794}, {name = "📸 إضافة 098 📸", v = 3425330}, {name = "📸 إضافة 099 📸", v = 3490866},
    {name = "📸 إضافة 100 📸", v = 3556402},
})

-- ═══════════════════════════════════════════════════════════
-- 🌾 قائمة منتجات الشونة (168 منتج)
-- ═══════════════════════════════════════════════════════════
local barnProductsList = {
    {name = "قمح 🌾", values = {1701345034, 29793, 0, 0, 0, 0}},
    {name = "ذرة 🌽", values = {1919902472, 110, 644781648, 17, 35749913, 0}},
    {name = "أرز 🍚", values = {1667854856, 7471205, 6645106, 17, 35749913, 0}},
    {name = "جزر 🥕", values = {1918984972, 7630706, 644781648, 17, 35749913, 0}},
    {name = "طماطم 🍅", values = {1836020746, 1694528609, 7959154, 17, 35749913, 0}},
    {name = "بطاطس 🥔", values = {1953460236, 7304289, 7959154, 17, 35749913, 0}},
    {name = "فلفل 🌶️", values = {1885696012, 7497072, 6645106, 17, 35749913, 0}},
    {name = "فراولة 🍓", values = {1920234260, 1700951905, 7959154, 17, 35749913, 0}},
    {name = "تفاح 🍎", values = {1886413066, 1744856428, 1835362304, 28021, 35749913, 0}},
    {name = "نعناع 🌿", values = {1852402952, 1744830580, 1835362304, 28021, 35749913, 0}},
    {name = "قصب السكر 🎋", values = {1735750418, 1633907297, 637560174, 17, 35749913, 0}},
    {name = "القطن ☁️", values = {1953456908, 7237492, 637560174, 17, 35749913, 0}},
    {name = "كاكاو 🍫", values = {1667326730, 28513, 7959154, 17, 35749913, 0}},
    {name = "شجرة المطاط 🌳", values = {1651864084, 1416783202, 6645106, 17, 35749913, 0}},
    {name = "حرير 🧵", values = {1818850056, 1416757355, 6645106, 17, 35749913, 0}},
    {name = "شجرة الصنوبر 🌲", values = {1852403720, 1694498917, 7959154, 17, 35749913, 0}},
    {name = "زهرة 🌸", values = {1936683536, 1701139301, 6619236, 17, 35749913, 0}},
    {name = "ياسمين 🌼", values = {1935763982, 1701734765, 1835362304, 28021, 35749913, 0}},
    {name = "زهرة الأفندر 💜", values = {1986096144, 1701080677, 1835335794, 28021, 35749913, 0}},
    {name = "نبات القهوة ☕", values = {1718575884, 6645094, 1835362304, 28021, 35749913, 0}},
    {name = "فول الصويا 🫘", values = {2037347086, 1851876706, 1835362304, 28021, 35749913, 0}},
    {name = "بلوط الفلين 🌰", values = {1919902472, 1851850859, 1835362304, 28021, 35749913, 0}},
    {name = "مصنع الشاي 🍵", values = {1634038798, 1752397154, 1835362304, 28021, 35749913, 0}},
    {name = "نبات الفول السوداني 🥜", values = {1634037772, 7632238, 1835362304, 28021, 35749913, 0}},
    {name = "علف الأبقار 🐄", values = {2003788558, 1684366694, 1835335680, 28021, 35749913, 0}},
    {name = "علف الدجاج 🐔", values = {1768448790, 1852140387, 1684366694, 27904, 35749913, 0}},
    {name = "علف الخروف 🐑", values = {1701344018, 1701212261, 1677747301, 27904, 35749913, 0}},
    {name = "طعام الخنزير 🐷", values = {1734963214, 1684366694, 1677747200, 27904, 35749913, 0}},
    {name = "غذاء النحل 🐝", values = {1701143054, 1684366694, 1677747200, 27904, 35749913, 0}},
    {name = "مادة 📦", values = {1937075480, 1869574760, 1701144173, 100, 35749913, 0}},
    {name = "حليب 🥛", values = {1818848520, 1869545579, 1701144173, 100, 35749913, 0}},
    {name = "بيضة 🥚", values = {1734829318, 1869545472, 1701144173, 100, 35749913, 0}},
    {name = "صوف 🐑", values = {1869575944, 1869545580, 1701144173, 100, 35749913, 0}},
    {name = "لحم مقدد 🥓", values = {1667326474, 1862299247, 1701144173, 100, 35749913, 0}},
    {name = "شمع العسل 🍯", values = {1852794898, 1868790117, 1694524013, 100, 35749913, 0}},
    {name = "عيش الغراب 🍄", values = {1937075472, 1869574760, 1694498925, 100, 35749913, 0}},
    {name = "خبز 🍞", values = {1701995018, 1862296673, 1694498925, 100, 35749913, 0}},
    {name = "بسكويت 🍪", values = {1869570828, 6646123, 1694498925, 100, 35749913, 0}},
    {name = "خبز البطاطس 🥔", values = {1953460246, 1651471457, 1684104562, 0, 35749913, 0}},
    {name = "بيتزا 🍕", values = {2053730314, 1644192122, 1684104562, 0, 35749913, 0}},
    {name = "كعك 🥮", values = {1734435338, 1644194917, 1684104562, 0, 35749913, 0}},
    {name = "خبز الموز 🍌", values = {1851875862, 1650552417, 1684104562, 0, 35749913, 0}},
    {name = "كعك عيش الغراب 🍄", values = {1937075478, 1869574760, 1701400685, 0, 35749913, 0}},
    {name = "فطيرة التفاح 🥧", values = {1920234254, 1818584181, 1701400576, 0, 35749913, 0}},
    {name = "بيتزا طعام البحر 🍕", values = {1918987542, 1885695593, 1635416681, 6646016, 35749913, 0}},
    {name = "فشار 🍿", values = {1886351374, 1852993379, 1818584320, 1802465123, 33580393, 0}},
    {name = "رقائق الذرة 🌽", values = {1919902482, 1768448878, 1811968880, 1802465123, 33580393, 0}},
    {name = "شرائح البطاطس 🍟", values = {1768448778, 1761637232, 1811968880, 1802465123, 33580393, 0}},
    {name = "جاربرولا 🥨", values = {1634887438, 1634496366, 1811968768, 1802465123, 33580393, 0}},
    {name = "كانابيه 🍢", values = {1851876108, 6647905, 1811968768, 1802465123, 33580393, 0}},
    {name = "لحم مقدد رائع 🥓", values = {1634494230, 1650746746, 1852793697, 1802465024, 33580393, 0}},
    {name = "أرز منفوش 🍚", values = {1718972436, 1919182182, 6644585, 1802465024, 33580393, 0}},
    {name = "عيش الغراب مجفف 🍄", values = {1769104412, 1968006245, 1869768819, 7564655, 33580393, 0}},
    {name = "فول سوداني 🥜", values = {1818325784, 1885627764, 1970168165, 7536756, 33580393, 0}},
    {name = "مخلل اللبن 🥛", values = {1818848530, 1634235243, 1677747563, 7536761, 33580393, 0}},
    {name = "بطاطس مقلية 🍟", values = {1701996054, 1718117230, 1936025970, 7536640, 33580393, 0}},
    {name = "شطيرة لحم 🥪", values = {1851880208, 1667856228, 1935999080, 7536640, 33580393, 0}},
    {name = "برجر بالجبن 🍔", values = {1701339928, 1650815845, 1701278325, 7536754, 33580393, 0}},
    {name = "بطاطس مخبوزة 🥔", values = {1801544218, 1869636709, 1869898100, 29541, 33580393, 0}},
    {name = "برجر سمك 🐟", values = {1936287252, 1920295528, 7497063, 29541, 33580393, 0}},
    {name = "سمك ورائق 🐟", values = {1936287252, 1751342952, 7565417, 29541, 33580393, 0}},
    {name = "كريب بزبدة الفول السوداني 🥜", values = {1634037786, 1601466222, 1885696611, 29541, 33580393, 0}},
    {name = "كريمة 🍦", values = {1701995274, 1728081249, 1879076213, 29541, 33580393, 0}},
    {name = "زبدة 🧈", values = {1953849868, 7497076, 1879076213, 29541, 33580393, 0}},
    {name = "جبن 🧀", values = {1701339916, 6648677, 1879076213, 29541, 33580393, 0}},
    {name = "زبادي أحمر 🍓", values = {1735358732, 7631477, 1879076213, 29541, 33580393, 0}},
    {name = "زبادي الخوخ 🍑", values = {1634037782, 1870227555, 1953658215, 29440, 33580393, 0}},
    {name = "توفو 🍲", values = {1718580232, 1870200949, 1953658215, 29440, 33580393, 0}},
    {name = "حليب نباتي 🥛", values = {2037347086, 1802266989, 1953658112, 29440, 33580393, 0}},
    {name = "سكر 🍬", values = {1735750410, 1795191393, 1953658112, 29440, 33580393, 0}},
    {name = "شراب 🍯", values = {1920561930, 1795190901, 1953658112, 29440, 33580393, 0}},
    {name = "كراميلا 🍮", values = {1918984974, 1818586465, 1953658112, 29440, 33580393, 0}},
    {name = "كراميلا العسل 🍯", values = {1852794904, 1633909093, 1701667186, 108, 33580393, 0}},
    {name = "مخلوط آيسكريم كراميل 🍨", values = {1701013776, 1634038371, 2003763309, 6644480, 33580393, 0}},
    {name = "زبادي مثلج 🍦", values = {1869768216, 2037278074, 1920296815, 6619252, 33580393, 0}},
    {name = "مصاصة 🍭", values = {1970431504, 1667855465, 1920270437, 6619252, 33580393, 0}},
    {name = "آيسكريم 🍦", values = {1802724620, 7302505, 1920270437, 6619252, 33580393, 0}},
    {name = "توفي 🍬", values = {1718580236, 6645094, 1650419060, 2037280373, 1701995264, 0}},
    {name = "عصا الحلوى 🍭", values = {1851876116, 1953724772, 7037801, 2037280373, 1701995264, 0}},
    {name = "شوكولاتة 🍫", values = {1869112082, 1634496355, 25972, 2037280373, 1701995264, 0}},
    {name = "حلوى مصاصة 🍬", values = {1819241488, 1869637996, 112, 2037280373, 1701995264, 0}},
    {name = "خطمي العسل 🍯", values = {1852794900, 1633909093, 7955566, 2037280373, 1701995264, 0}},
    {name = "شرائح الفواكه 🍉", values = {1970431508, 1701475433, 7957612, 2037280373, 1701995264, 0}},
    {name = "قطعة شوكولاتة 🍫", values = {1869112080, 1633840995, 7929970, 2037280373, 1701995264, 0}},
    {name = "حلوى الشاي الأخضر 🍵", values = {1634038804, 1684955491, 7562601, 2037280373, 1701995264, 0}},
    {name = "حلوى النعناع 🍬", values = {1852402970, 1819241588, 1869637996, 2030072688, 1701995264, 0}},
    {name = "صلصة الفلفل الأحمر 🥫", values = {1969320714, 1811965283, 1869637996, 2030072688, 1701995264, 0}},
    {name = "مربى الفراولة 🍓", values = {1920234268, 1700951905, 1601794674, 7168362, 1694523648, 0}},
    {name = "مرملاد 🍊", values = {1634037778, 1784637539, 1593863521, 7168362, 1694523648, 0}},
    {name = "مربى البطيخ 🍉", values = {1952544540, 1701671525, 1601073004, 7168362, 1694523648, 0}},
    {name = "مربى البرقوق 🍑", values = {1970040848, 1634361197, 1601044589, 7168362, 1694523648, 0}},
    {name = "جيلي العنب 🍇", values = {1634887444, 1601398128, 7168362, 7168362, 1694523648, 0}},
    {name = "مربى الورد 🌹", values = {1936683534, 1835092581, 7168256, 7168362, 1694523648, 0}},
    {name = "زبدة الفول السوداني ??", values = {1634037786, 1601467758, 1953789282, 29285, 1694523648, 0}},
    {name = "مربى التفاح 🍎", values = {1886413072, 1634362732, 1953759341, 29285, 1694523648, 0}},
    {name = "الناتشوز 🌮", values = {1667329548, 7565160, 1869637996, 2030072688, 1701995264, 0}},
    {name = "التاكو 🌮", values = {1667331080, 7536751, 1869637996, 2030072688, 1701995264, 0}},
    {name = "حساء عيش الغراب 🍄", values = {1937075480, 1869574760, 1970230125, 2030043248, 1701995264, 0}},
    {name = "حساء الجازبشوا 🥣", values = {2053203728, 1751343472, 1970208879, 2030043248, 1701995264, 0}},
    {name = "البوريتو 🌯", values = {1920295438, 1869900146, 1970208768, 2030043248, 1701995264, 0}},
    {name = "لقيمات جلابينو المحشو 🌶️", values = {1818323472, 1852141665, 1970208879, 2030043248, 1701995264, 0}},
    {name = "حساء الذرة 🥣", values = {1919902482, 1869832046, 1962963061, 2030043248, 1701995264, 0}},
    {name = "صوص الخلد 🥫", values = {1819241736, 1869807717, 1962963061, 2030043248, 1701995264, 0}},
    {name = "سلطة البحر 🥗", values = {1634038554, 1685024614, 1818325855, 25697, 1694523648, 0}},
    {name = "لفافة الشوسي ??", values = {1937077002, 1677748584, 1818325855, 25697, 1694523648, 0}},
    {name = "حساء جوز الهند 🥥", values = {1970238216, 1677721712, 1818325855, 25697, 1694523648, 0}},
    {name = "شوسي سرطان البحر 🦀", values = {1651469340, 1919251571, 1734962783, 6910569, 1694523648, 0}},
    {name = "سلطة عشب 🥗", values = {1634038552, 1684366711, 1634492787, 6881380, 1694523648, 0}},
    {name = "اسكلوب الشوسي 🍣", values = {1633907480, 1886350444, 1752397171, 6881385, 1694523648, 0}},
    {name = "غزل 🧶", values = {1869575956, 1650550380, 6515058, 2030043248, 1701995264, 0}},
    {name = "نسيج القطن 🧵", values = {1953456920, 1718513524, 1769103969, 2030043235, 1701995264, 0}},
    {name = "نسيج الحرير 🧵", values = {1818850068, 1650550379, 6515058, 2030043235, 1701995264, 0}},
    {name = "خيط نايلون 🧵", values = {1819897366, 1752460911, 1684104562, 2030071808, 1701995264, 0}},
    {name = "مطاط 🪵", values = {1651864076, 7497058, 1845523041, 1828746085, 1701970021, 0}},
    {name = "بلاستيك 🧴", values = {1634496526, 1667855475, 1845522944, 1828746085, 1701970021, 0}},
    {name = "غراء 🧴", values = {1970038536, 1667825765, 1845522944, 1828746085, 1701970021, 0}},
    {name = "قميص 👕", values = {1768452874, 1744860274, 1684104562, 2030071808, 1701995264, 0}},
    {name = "سترة 🧥", values = {1702327054, 1919251553, 1684104448, 2030071808, 1701995264, 0}},
    {name = "معطف 🧥", values = {1634689800, 1919221876, 1684104448, 2030071808, 1701995264, 0}},
    {name = "قبعة 🎩", values = {1952540678, 1919221760, 1684104448, 2030071808, 1701995264, 0}},
    {name = "فستان 👗", values = {1701995530, 1912632179, 1684104448, 2030071808, 1701995264, 0}},
    {name = "بذلة 👔", values = {1769304840, 1912602740, 1684104448, 2030071808, 1701995264, 0}},
    {name = "القبعة البافارية 👒", values = {1919513622, 1634036847, 1952532590, 2030071808, 1701995264, 0}},
    {name = "ثوب السهرة 👗", values = {1702257944, 1735289198, 1936028260, 2030043251, 1701995264, 0}},
    {name = "طاولة 🪑", values = {1650553866, 1291871596, 1811968097, 1684369519, 1694523753, 0}},
    {name = "كرسي 🪑", values = {1634231050, 1291874921, 1811968097, 1684369519, 1694523753, 0}},
    {name = "أريكة 🛋️", values = {1970234122, 1291872355, 1811968097, 1684369519, 1694523753, 0}},
    {name = "سرير 🛏️", values = {1684365830, 1291872256, 1811968097, 1684369519, 1694523753, 0}},
    {name = "مصباح الطابق 💡", values = {1869374996, 1818194543, 7368033, 1684369519, 1694523753, 0}},
    {name = "ورق 📄", values = {1885433866, 1811968613, 1845493868, 1828746085, 1701970021, 0}},
    {name = "منشفة ورقية 🧻", values = {1885433876, 1869902437, 7103863, 1828746085, 1701970021, 0}},
    {name = "ورق حائط 📜", values = {1818326804, 1885433964, 7565925, 1828746085, 1701970021, 0}},
    {name = "الكتاب 📚", values = {1869570568, 1885405291, 7565925, 1828746085, 1701970021, 0}},
    {name = "أكياس الشاي 🍵", values = {1634038798, 1936154978, 7565824, 1828746085, 1701970021, 0}},
    {name = "ثقل رياضي 🏋️", values = {1836409872, 1818583650, 1845493868, 1828746085, 1701970021, 0}},
    {name = "خف 🥿", values = {1768711698, 1869375088, 29552, 1684369519, 1694523753, 0}},
    {name = "صندل 👡", values = {1851880206, 1936482660, 29440, 1684369519, 1694523753, 0}},
    {name = "حذاء رياضي 👟", values = {1701737232, 1919249249, 115, 1684369519, 1694523753, 0}},
    {name = "حذاء برباط 👞", values = {1869570570, 1912632180, 115, 1684369519, 1694523753, 0}},
    {name = "حذاء بكعب عالي 👠", values = {1701144586, 1912632172, 115, 1684369519, 1694523753, 0}},
    {name = "حذاء ثقيل 🥾", values = {2003788818, 1869562478, 29556, 1684369519, 1694523753, 0}},
    {name = "زجاجة بلاستيكية 🧴", values = {1634496538, 1667855475, 1953787746, 1677747564, 1694523753, 0}},
    {name = "ألعاب 🧸", values = {2037347336, 1667825779, 1953787746, 1677747564, 1694523753, 0}},
    {name = "كرة ⚽", values = {1818321416, 1667825772, 1953787746, 1677747564, 1694523753, 0}},
    {name = "قارب قابل للنفخ 🚤", values = {1701345034, 1660972133, 1953787746, 1677747564, 1694523753, 0}},
    {name = "الشطكوك 🍢", values = {1969779478, 1701606516, 1801678691, 1677747456, 1694523753, 0}},
    {name = "تشكيل الطين 🟫", values = {1634488340, 1667855475, 6647401, 1677747456, 1694523753, 0}},
    {name = "قلادة 📿", values = {1852141582, 1953390948, 7037696, 1677747456, 1694523753, 0}},
    {name = "خاتم 💍", values = {1852404232, 1953366119, 7037696, 1677747456, 1694523753, 0}},
    {name = "قلادة من اللؤلؤ 📿", values = {1634037778, 1701735538, 27491, 1677747456, 1694523753, 0}},
    {name = "أقراط 💎", values = {1918985488, 1735289202, 115, 1677747456, 1694523753, 0}},
    {name = "تاج 👑", values = {1634296844, 7169380, 115, 1677747456, 1694523753, 0}},
    {name = "أقراط من الريش 🪶", values = {1634035230, 1919248500, 1920098629, 1936158313, 1694523648, 0}},
    {name = "عيش غراب بالكراميل 🥐", values = {1937075480, 1869574760, 1634361197, 7143533, 1694523648, 0}},
    {name = "شعيرية الأرز 🍜", values = {1667854870, 1869504357, 1701602415, 6881280, 1694523648, 0}},
    {name = "صلصة الفول السوداني 🥜", values = {1634235412, 1634951017, 6644597, 25697, 1694523648, 0}},
    {name = "تورته مالحة 🥧", values = {1769304332, 6645859, 6644597, 25697, 1694523648, 0}},
    {name = "لحم مقدد وبيض 🥓", values = {1667326484, 1700753007, 7563111, 25697, 1694523648, 0}},
    {name = "سمك مقلي 🐟", values = {1769104916, 1717527653, 6845289, 25697, 1694523648, 0}},
    {name = "طبق الأرز العميق 🍚", values = {1667854876, 1633902437, 1919251315, 6646895, 1694523648, 0}},
    {name = "فطائر بالعسل 🥞", values = {1851879438, 1701536099, 1919251200, 6646895, 1694523648, 0}},
    {name = "سرطان مخبوز 🦀", values = {1801544218, 1818190949, 1953718895, 29285, 1694523648, 0}},
    {name = "أومليت سرطان البحر 🍳", values = {1651469342, 1919251571, 2003136095, 1735554402, 1694523648, 0}},
    {name = "محارات صدقية مشوية 🦪", values = {1633907478, 1886350444, 2003135347, 1735554304, 1694523648, 0}},
    {name = "لحم مشوي 🥩", values = {1769105174, 1684368492, 1952539981, 1735554304, 1694523648, 0}},
    {name = "شمعة العلاج العطري 🕯️", values = {1869767190, 1631809143, 1701602414, 1735554304, 1694523648, 0}},
    {name = "العطر 🧴", values = {1919250458, 1701672294, 1953787714, 1728079212, 1694523648, 0}},
    {name = "الصابون المعطر 🧼", values = {1869374996, 1400006007, 7364975, 1728079212, 1694523648, 0}},
    {name = "البلسام 🧪", values = {1953459224, 1114533737, 1819571311, 1728053349, 1694523648, 0}},
    {name = "زيت الياسمين 🌼", values = {1869766936, 1769234797, 1768906595, 1728053356, 1694523648, 0}},
    {name = "معطر الهواء 🌬️", values = {1919508762, 1701996127, 1852139635, 1728082533, 1694523648, 0}},
    {name = "قناع وجه 🧖‍♀️", values = {1701995282, 1634561377, 1845521267, 1728082533, 1694523648, 0}},
    {name = "معجون أسنان 🪥", values = {1869575188, 1634756724, 6648947, 1728082533, 1694523648, 0}},
    {name = "كوكتيل الفيتامين ??", values = {1953068576, 1852403041, 1668244319, 1767994475, 1694498924, 0}},
    {name = "شراب العنب الفوار 🍇", values = {1634887442, 1768316784, 1660975738, 1767994475, 1694498924, 0}},
    {name = "سموزي الشوكولاتة 🍫", values = {1869112100, 1634496355, 1935631732, 1953460077, 6646120, 0}},
    {name = "البطيخ الطازج 🍉", values = {1952544544, 1701671525, 1601073004, 1936028262, 6619240, 0}},
    {name = "المزيج الاستوائي 🍹", values = {1869771800, 1633905008, 1768775532, 1935999096, 6619240, 0}},
    {name = "الشاي المثلج 🧊", values = {1819239184, 1702125412, 1768751201, 1935999096, 6619240, 0}},
    {name = "شاي مثلج بالنعناع 🌿", values = {1852402964, 1701013876, 6382964, 1935999096, 6619240, 0}},
    {name = "تفاح طازج 🍎", values = {1886413076, 1919313260, 6845285, 1935999096, 6619240, 0}},
    {name = "نقانق 🌭", values = {1953458190, 1735353439, 6845184, 1935999096, 6619240, 0}},
    {name = "نقانق ذرة 🌽", values = {1919902478, 1735353454, 6845184, 1935999096, 6619240, 0}},
    {name = "شطائر نقانق 🥪", values = {1701339928, 1600484197, 1701736291, 1935999097, 6619240, 0}},
    {name = "شطيرة جزر 🥕", values = {1918984986, 1601466226, 1685352296, 1929406319, 6619240, 0}},
    {name = "إسبريسو ☕", values = {1886610704, 1936942450, 1685323887, 1929406319, 6619240, 0}},
    {name = "كابتشينو ☕", values = {1885430548, 1667462512, 7302761, 1929406319, 6619240, 0}},
    {name = "كافيه موكا ☕", values = {1802464530, 1768448865, 28526, 1929406319, 6619240, 0}},
    {name = "شوكولاتة ساخنة ☕", values = {1953458202, 1869112159, 1634496355, 1929405812, 6619240, 0}},
    {name = "لاتيه جوز الهند 🥥", values = {1668244246, 1953853039, 1717662303, 1929405696, 6619240, 0}},
    {name = "عروسة 🪆", values = {1886744588, 7628144, 1717662303, 1929405696, 6619240, 0}},
    {name = "دومية الخزف 🎎", values = {1768448786, 1868849518, 1711303788, 1929405696, 6619240, 0}},
    {name = "دومية الموضة 👗", values = {1918984716, 6646114, 1711303788, 1929405696, 6619240, 0}},
    {name = "دومية قماشية 🧵", values = {1734439438, 1819045732, 1711303680, 1929405696, 6619240, 0}},
    {name = "الكوب ☕", values = {1735748870, 1819045632, 1711303680, 1929405696, 6619240, 0}},
    {name = "مقلاة القلبي 🍳", values = {2037540364, 7233904, 1711303680, 1929405696, 6619240, 0}},
    {name = "إبريق شاي 🫖", values = {1634038796, 7630704, 1711303680, 1929405696, 6619240, 0}},
    {name = "أدوات المائدة 🍴", values = {1953850126, 2037540204, 1711303680, 1929405696, 6619240, 0}},
    {name = "مجموعة حقل الشاي 🍵", values = {1634038812, 1701995875, 2037280621, 7629163, 6619240, 0}},
    {name = "مفرش المطبخ 🧺", values = {1953460240, 1851880563, 2037252196, 7629163, 6619240, 0}},
    {name = "الوسادة 🛏️", values = {1818849292, 7827308, 2037252196, 7629163, 6619240, 0}},
    {name = "السترة 🧥", values = {2003788820, 1667320430, 7628139, 7629163, 6619240, 0}},
    {name = "الحشوة الناعمة 🧸", values = {1987404810, 1660974181, 7628139, 7629163, 6619240, 0}},
    {name = "رداء وخف 🥋", values = {1952539168, 1651470952, 1768715109, 1919250544, 6619251, 0}},
    {name = "قيثارة 🎸", values = {1969976590, 1701602668, 1768715008, 1919250544, 6619251, 0}},
    {name = "ساكسفون 🎷", values = {2019652370, 1869115503, 1761633646, 1919250544, 6619251, 0}},
    {name = "طبلة 🥁", values = {1970430984, 1869086829, 1761633646, 1919250544, 6619251, 0}},
    {name = "أكورديون 🪗", values = {1667457298, 1768190575, 1761635951, 1919250544, 6619251, 0}},
    {name = "مزماز قصبي 🎺", values = {1851879438, 1701865840, 1761635840, 1919250544, 6619251, 0}},
    {name = "شاي أسود 🍵", values = {1634492944, 1702128483, 1761607777, 1919250544, 6619251, 0}},
    {name = "شاي ياسمين أبيض 🌼", values = {1768453904, 1702126964, 1761607777, 1919250544, 6619251, 0}},
    {name = "شاي الورد 🌹", values = {1936683534, 1634038885, 1761607680, 1919250544, 6619251, 0}},
    {name = "شاي الزبد 🧈", values = {1651078160, 1702130789, 1761607777, 1919250544, 6619251, 0}},
    {name = "شاي أولونغ بالحليب 🥛", values = {1819242252, 6778479, 1761607777, 1919250544, 6619251, 0}},
    {name = "كاستر الشوكولاتة 🍮", values = {1937072910, 1685217652, 1761607680, 1919250544, 6619251, 0}},
    {name = "شاي بالتفاح 🍎", values = {1886413072, 1702126956, 1761607777, 1919250544, 6619251, 0}},
    {name = "باقة زهور الصيف 💐", values = {1836413722, 1651664237, 1970369903, 1912632421, 6619251, 0}},
    {name = "باقة خضروات 🥦", values = {1734702624, 1650553957, 1868719468, 1702195573, 6619252, 0}},
    {name = "باقة زهور الزفاف 💍", values = {1769103896, 1868719460, 1702195573, 1702166644, 6619252, 0}},
    {name = "باقة حلوى 🍬", values = {1702327064, 1868723301, 1702195573, 1702166644, 6619252, 0}},
    {name = "سلة زهور 🧺", values = {1935761946, 1651795307, 1970369903, 1694528613, 6619252, 0}},
    {name = "باقة الشاي والقهوة ☕", values = {1634038816, 1717989219, 1868719461, 1702195573, 6619252, 0}},
    {name = "باقة زهور اللافندر 💜", values = {1769104408, 1818649701, 1919252335, 1702166643, 6619252, 0}},
    {name = "زيت الزيتون 🫒", values = {1768714000, 1768908150, 1919221868, 1702166643, 6619252, 0}},
    {name = "بروسكيتا 🍞", values = {1970430484, 1701340019, 6386804, 1702166643, 6619252, 0}},
    {name = "مكرونة أرابياتا 🍝", values = {1920098580, 1768055393, 6386785, 1702166643, 6619252, 0}},
    {name = "رافيولي 🥟", values = {1986097678, 1768714089, 6386688, 1702166643, 6619252, 0}},
    {name = "تيراميسو 🍰", values = {1919513616, 1936289121, 6357109, 1702166643, 6619252, 0}},
    {name = "لازنيا 🍝", values = {1935764494, 1634625377, 6356992, 1702166643, 6619252, 0}},
    {name = "بالون 🎈", values = {1919508756, 1819042146, 7237487, 1702166643, 6619252, 0}},
    {name = "حلوى غزل البنات 🍭", values = {1953456918, 1131310964, 2036624993, 1702166528, 6619252, 0}},
    {name = "فقاعات الصابون 🫧", values = {1634693910, 1651851888, 1936026722, 1702166528, 6619252, 0}},
    {name = "لي 🌺", values = {1768254470, 1651851776, 1936026722, 1702166528, 6619252, 0}},
    {name = "بينياتا 🪅", values = {1852403724, 6386785, 1936026722, 1702166528, 6619252, 0}},
    {name = "عجينة 🥣", values = {1970234378, 26727, 1936026722, 1702166528, 6619252, 0}},
    {name = "خضروات مجمدة 🧊", values = {1869768224, 1986946426, 1952802661, 1701601889, 6619251, 0}},
    {name = "مزيج مأكولات بحرية 🦐", values = {1634038558, 1685024614, 1801678691, 1818845556, 6619136, 0}},
    {name = "زلابية 🥨", values = {1870227210, 1677746554, 1801678691, 1818845556, 6619136, 0}},
    {name = "وجبة مغلفة 🥟", values = {1634038292, 1970043236, 6841198, 1818845556, 6619136, 0}},
    {name = "فاكهة مجمدة 🍓", values = {1970431504, 1768780905, 6815864, 1818845556, 6619136, 0}},
    {name = "كعكة بالنعناع 🌿", values = {1852402960, 1801544564, 6815845, 1818845556, 6619136, 0}},
    {name = "كعكة شوكولاتة 🍫", values = {1869112090, 1634496355, 1633903988, 1811965291, 6619136, 0}},
    {name = "كعكة جزر 🥕", values = {1918984980, 1668575090, 6646625, 1811965291, 6619136, 0}},
    {name = "كعكة الفراولة 🍓", values = {1920234268, 1700951905, 1668903538, 6646625, 6619136, 0}},
    {name = "كعكة زفاف 🎂", values = {1684371222, 1735289188, 1701536099, 6646528, 6619136, 0}},
    {name = "كعكة قهوة ☕", values = {1718575892, 1667589478, 6646625, 6646528, 6619136, 0}},
    {name = "كرسي حديقة 🪑", values = {1970236428, 6645614, 6646625, 6646528, 6619136, 0}},
    {name = "تمثال الحديقة 🗿", values = {1918986006, 1735288164, 1701670766, 6646528, 6619136, 0}},
    {name = "أدوات حديقة 🪴", values = {1869575182, 1952805740, 1701670656, 6646528, 6619136, 0}},
    {name = "خرطوم 💦", values = {1920100636, 1952540521, 1752067945, 6648687, 6619136, 0}},
    {name = "أصيص 🪴", values = {1869374994, 1953654135, 1744855669, 6648687, 6619136, 0}},
    {name = "عظمة مطاطية 🦴", values = {1952804876, 7958388, 1744855669, 6648687, 6619136, 0}},
    {name = "فار بالزنبرك 🐀", values = {1952539404, 7958388, 1744855669, 6648687, 6619136, 0}},
    {name = "وعاء ماء 🥣", values = {1952544530, 1868722789, 1744858231, 6648687, 6619136, 0}},
    {name = "فراش حيوانات أليفة 🐶", values = {1952539406, 1702256995, 1744858112, 6648687, 6619136, 0}},
    {name = "رمل فضلات القطط 🐱", values = {1952539410, 1953786220, 1744859749, 6648687, 6619136, 0}},
    {name = "فلافل 🧆", values = {1818322446, 1818584673, 1744859648, 6648687, 6619136, 0}},
    {name = "حساء ميسو 🍜", values = {1936289040, 1970238319, 1744830576, 6648687, 6619136, 0}},
    {name = "كعكة جبن نباتية 🍰", values = {1734702622, 1751346785, 1702061413, 1701536099, 6619136, 0}},
    {name = "حمص فول الصويا 🥣", values = {1836410892, 7566701, 1702061413, 1701536099, 6619136, 0}},
    {name = "جواكامولي 🥑", values = {1635084050, 1869439331, 1694524780, 1701536099, 6619136, 0}},
    {name = "حقيبة ظهر 🎒", values = {2003136022, 1801675106, 1801675120, 1701536000, 6619136, 0}},
    {name = "حقيبة منسوجة 🧺", values = {1935761932, 7628139, 1801675120, 1701536000, 6619136, 0}},
    {name = "حقيبة يد صغيرة 👜", values = {1851877390, 1734435428, 1801675008, 1701536000, 6619136, 0}},
    {name = "حقيبة 👛", values = {1769304848, 1935762292, 1801650277, 1701536000, 6619136, 0}},
    {name = "حقيبة أطفال 👶", values = {1684630286, 1734435443, 1801650176, 1701536000, 6619136, 0}},
    {name = "فرشاة تنظيف 🧹", values = {1970430474, 1728079987, 1801650176, 1701536000, 6619136, 0}},
    {name = "موزع الصابون 🧴", values = {1936286738, 1936614768, 1795191397, 1701536000, 6619136, 0}},
    {name = "حبل الغسيل ومشابك الغسيل 👕", values = {1869374230, 1936025716, 1701734764, 1701536000, 6619136, 0}},
    {name = "المكبس 🧹", values = {1970040846, 1919248238, 1701734656, 1701536000, 6619136, 0}},
    {name = "منضفة ريش 🪶", values = {1937073164, 7497076, 1701734656, 1701536000, 6619136, 0}},
    {name = "قفازات مطاطية 🧤", values = {1869375244, 7562614, 1701734656, 1701536000, 6619136, 0}},
    {name = "ممحاة 🧽", values = {1634886924, 7497075, 1701734656, 1701536000, 6619136, 0}},
    {name = "ورق ملاحظات لاصق 📝", values = {1769239312, 1919249251, 1701707891, 1701536000, 6619136, 0}},
    {name = "لوحة نشرات 📌", values = {1919902482, 1634689643, 1694524530, 1701536000, 6619136, 0}},
    {name = "قلم تحديد 🖊️", values = {1918987532, 7497067, 1694524530, 1701536000, 6619136, 0}},
    {name = "طبق خضروات مشكلة بالصلصة 🥗", values = {1952543254, 1970238561, 1701604457, 1701536000, 6619136, 0}},
    {name = "خبز البروفيتول 🥖", values = {1869770776, 1702127974, 1701605234, 1701511283, 6619136, 0}},
    {name = "سلطة نيسواز 🥗", values = {1667853838, 1702062447, 1701605120, 1701511283, 6619136, 0}},
    {name = "حساء سمك مبهر ??", values = {1970233882, 1634495593, 1936286050, 1694524787, 6619136, 0}},
    {name = "الموز 🍌", values = {1851875852, 6385249, 1936286050, 1694524787, 6619136, 0}},
    {name = "جوز الهند 🥥", values = {1668244238, 1953853039, 1936285952, 1694524787, 6619136, 0}},
    {name = "الأناناس 🍍", values = {1852403730, 1886413157, 1929405804, 1694524787, 6619136, 0}},
    {name = "الخوخ 🍑", values = {1634037770, 1879074915, 1929405804, 1694524787, 6619136, 0}},
    {name = "البطيخ 🍉", values = {1952544532, 1701671525, 7237484, 1694524787, 6619136, 0}},
    {name = "البرقوق 🍇", values = {1970040840, 1701642349, 7237484, 1694524787, 6619136, 0}},
    {name = "العنب 🍇", values = {1634887436, 7562608, 7237484, 1694524787, 6619136, 0}},
    {name = "الزيتون 🫒", values = {1768713994, 25974, 7237484, 1694524787, 6619136, 0}},
    {name = "الليمون 🍋", values = {1835363338, 28271, 7237484, 1694524787, 6619136, 0}},
    {name = "السمك 🐟", values = {1936287240, 104, 7237484, 1694524787, 6619136, 0}},
    {name = "الجمبري 🍤", values = {1919447820, 7368041, 7237484, 1694524787, 6619136, 0}},
    {name = "سرطان البحر 🦀", values = {1651469326, 1919251571, 7237376, 1694524787, 6619136, 0}},
    {name = "أفوكادو 🥑", values = {1870029070, 1868849507, 7237376, 1694524787, 6619136, 0}},
    {name = "مانجو 🥭", values = {1851878668, 3239783, 7237376, 1694524787, 6619136, 0}},
    {name = "صبار 🌵", values = {1869373704, 3211365, 7237376, 1694524787, 6619136, 0}},
    {name = "سبيكة البرونز 🟫", values = {1869759002, 1113946734, 1768713333, 1694527087, 6619136, 0}},
    {name = "سبيكة الفضة ⬜", values = {1818841882, 1114793334, 1768713333, 1694527087, 6619136, 0}},
    {name = "سبيكة الذهب 🟨", values = {1819232022, 1819624036, 1852795244, 1694526976, 6619136, 0}},
    {name = "سبيكة البلاتين ⬜", values = {1634488350, 1970170228, 1819624045, 1852795244, 6619136, 0}},
    {name = "الطين 🟤", values = {1634493192, 1970143353, 1819624045, 1852795244, 6619136, 0}},
    {name = "الريش الناعم 🪶", values = {2003788822, 1634027118, 1919248500, 1852795136, 6619136, 0}},
    {name = "الريش الملون 🪶", values = {1734959636, 1952539974, 7497064, 1852795136, 6619136, 0}},
    {name = "عشب البحر 🌿", values = {1634038542, 1684366711, 7496960, 1852795136, 6619136, 0}},
    {name = "المحارات الصدفية 🐚", values = {1633907470, 1886350444, 7496960, 1852795136, 6619136, 0}},
    {name = "اللآلئ ⚪", values = {1634037770, 1879075954, 7496960, 1852795136, 6619136, 0}}
}



-- ═══════════════════════════════════════════════════════════
-- 18) قوائم البناء والكاش والمستويات
-- ═══════════════════════════════════════════════════════════
showBuildMenu = function()
    currentMenuFn = showBuildMenu
    local items = {}
    for i, op in ipairs(buildOperations) do items[i] = op.icon .. " " .. op.name end
    items[#items + 1] = "↩️ رجـــــــــــــــــــــــــــــــــوع"
    local c = gg.choice(items, nil, "🏗️ الشونة والبناء")
    if not c then return end
    if c == #items then currentMenuFn = showMenuB; return showMenuB() end
    local op = buildOperations[c]; if op then searchAndReplace(op) end
end

showPlaneDecorMenu = function()
    currentMenuFn = showPlaneDecorMenu
    local items = {}
    for i, op in ipairs(planeDecorOps) do items[i] = op.icon .. " " .. op.name end
    items[#items + 1] = "↩️ رجـــــــــــــــــــــــــــــــــوع"
    local c = gg.choice(items, nil, "✈️ زينة الطائرة")
    if not c then return end
    if c == #items then currentMenuFn = showCityDecorMenu; return showCityDecorMenu() end
    local op = planeDecorOps[c]; if op then searchAndReplace(op) end
end

showCashMenu = function()
    currentMenuFn = showCashMenu
    local items = {}
    for i, item in ipairs(cashEventItems) do items[i] = item.name end
    items[#items + 1] = "↩️ رجـــــــــــــــــــــــــــــــــوع"
    local c = gg.choice(items, nil, "💸 الكاش وهدايا الأحداث")
    if not c then return end
    if c == #items then currentMenuFn = showMenuB; return showMenuB() end

    local item = cashEventItems[c]
    if item then
        runGroup({
            list         = {{name = item.name, values = item.values}},
            title        = "💸 " .. item.name,
            askCount     = (item.count == true),   -- ✅ بعضها يسأل عن العدد
            stickersMode = false
        })
    end
end
-- ═══════════════════════════════════════════════════════════
-- 🗺️ دالة توسيع جميع الأراضي (بدون أدوات)
-- ═══════════════════════════════════════════════════════════

-- 📢 جدول الأشعارات (منظم لسهولة التعديل)
local LAND_EXPANSION_MESSAGES = {
    SEARCHING       = "🔍 جاري البحث عن الأراضي...",
    NO_RESULTS      = "❌ لم يتم العثور على نتائج",
    SUCCESS_ALERT   = "✅ لقد تم فتح جميع الأراضي",
    SUCCESS_TOAST   = "✅ اذا لم يتم فتح جميع الاراضي استخدم هذه الداله مجددا",
    NO_MODIFIED     = "❌ لم يتم تعديل أي عنوان",
    COUNT_PREFIX    = "🎯 تم فتح: ",
    COUNT_SUFFIX    = " قطعة أرض"
}

-- 🎯 القيم الثابتة للبحث والتعديل
local LAND_SEARCH_PATTERN = "1886938387X368"
local LAND_NEW_VALUE      = 6
local LAND_MAX_RESULTS    = 250

-- 🗺️ الدالة الرئيسية لتوسيع الأراضي
local function expandAllLands()
    gg.clearResults()
    gg.setVisible(false)
    gg.toast(LAND_EXPANSION_MESSAGES.SEARCHING)

    -- البحث عن نمط الأراضي
    gg.searchNumber(LAND_SEARCH_PATTERN, gg.TYPE_DWORD)

    local results = gg.getResults(LAND_MAX_RESULTS)
    if #results == 0 then
        gg.toast(LAND_EXPANSION_MESSAGES.NO_RESULTS)
        return false
    end

    -- بناء جدول التعديلات
    local modifications = {}
    for _, v in ipairs(results) do
        table.insert(modifications, {
            address = v.address,
            flags   = gg.TYPE_DWORD,
            value   = LAND_NEW_VALUE
        })
    end

    -- تنفيذ التعديل
    if #modifications > 0 then
        gg.setValues(modifications)
        gg.clearResults()
        gg.alert(LAND_EXPANSION_MESSAGES.SUCCESS_ALERT)
        gg.toast(LAND_EXPANSION_MESSAGES.SUCCESS_TOAST ..
                 " (" .. LAND_EXPANSION_MESSAGES.COUNT_PREFIX ..
                 #modifications ..
                 LAND_EXPANSION_MESSAGES.COUNT_SUFFIX .. ")")
        return true
    else
        gg.toast(LAND_EXPANSION_MESSAGES.NO_MODIFIED)
        return false
    end
end


cityDevelopment = function()
    currentMenuFn = cityDevelopment
    local choice = gg.choice({
        "🌟 إظهـــار حـــدث الثـــروة",
        "🌑 إخفـــاء حـــدث الثـــروة",
        "🔓 فتـــح جميـــع الأراضـــي",
        "🗺️ مغـــامرة الخريطـــة",
        "↩️ رجـــــــــــــــــــــــــــــــــوع"
    }, nil, "🏙️ تطوير المدينة")

    if not choice or choice == 5 then
        currentMenuFn = showMainMenu
        return showMainMenu()
    end

    if choice == 1 then
        setWealthEvent(1500)

    elseif choice == 2 then
        setWealthEvent(1)

    elseif choice == 3 then
        -- ✅ استدعاء الدالة المُصلحة
        expandAllLands()

    elseif choice == 4 then
        local sub = gg.choice({
            "↩️ رجـــــــــــــــــــــــــــــــــوع",
            "🏆 ربـــح المرحلـــة الأولـــى والحصـــول علـــى الجائـــزة",
            "🏆 ربـــح المرحلـــة الثانيـــة مـــن الرحلـــة الاستكشـــافية"
        }, nil, "🗺️ مغامرة الخريطة")
        if not sub or sub == 1 then return cityDevelopment() end

        gg.clearResults(); gg.setVisible(false)
        gg.searchNumber("1886930200;1953064037;256::121", gg.TYPE_DWORD)
        gg.refineNumber("256", gg.TYPE_DWORD)
        local results = gg.getResults(1000)
        if #results == 0 then gg.toast("❌ لا توجد نتائج"); return end

        if sub == 2 then
            local mods = {}
            for _, v in ipairs(results) do
                table.insert(mods, {address = v.address + 0xC, flags = gg.TYPE_DWORD, value = 1})
            end
            gg.setValues(mods)
            gg.toast("✅ تم ربح المرحلة الأولى")
        elseif sub == 3 then
            local chk = {}
            for i, v in ipairs(results) do
                chk[i] = {address = v.address + 0x4, flags = gg.TYPE_DWORD}
            end
            local vals = gg.getValues(chk)
            local mods = {}
            for i, v in ipairs(results) do
                if vals[i].value ~= 0 then
                    table.insert(mods, {address = v.address + 0xC, flags = gg.TYPE_DWORD, value = 10000})
                end
            end
            if #mods > 0 then
                gg.setValues(mods)
                gg.toast("✅ تم ربح المرحلة الثانية (" .. #mods .. ")")
            else
                gg.toast("⚠️ لا نتائج صالحة")
            end
        end
        gg.clearResults()
    end
end
-- ═══════════════════════════════════════════════════════════
-- 🎁 رفع المستوى عن طريق الهدية 29
-- ═══════════════════════════════════════════════════════════
function goldenGift29()
    local giftItem = {
        name   = "🏗️ تم رفع المستوى بنجاح",
        values = {1886938374, 0, 0, 0, 0, 0}
    }
    return startSequentialReplacement({{name = giftItem.name, values = giftItem.values}}, true)
end


showLevelMenu = function()
    currentMenuFn = showLevelMenu
    local c = gg.choice({
        "↩️ رجـــــــــــــــــــــــــــــــــوع",
        "🚁 رفـــع المستـــوى بالهلوكبـــتر",
        "🌾 رفـــع المستـــوى بالقمـــح",
        "🎁 رفـــع المستـــوى عـــن طريـــق الهديـــه 29",
        "❌ الخـــــــروج"
    }, nil, "⭐ رفع المستوى")
    
    if not c or c == 1 then 
        currentMenuFn = showMainMenu
        return showMainMenu() 
    end
    
    if     c == 2 then Sefyj()
    elseif c == 3 then goldenChards()
    elseif c == 4 then goldenGift29()
    elseif c == 5 then os.exit() 
    end
end

showMatchingColorGifts = function()
    currentMenuFn = showMatchingColorGifts
    local items = {
        "↩️ رجـــــــــــــــــــــــــــــــــوع",
        "🔧 تفعيـــل الدبـــل الاصفـــر x2",
        "🔮 تفعيـــل الدبـــل البنفســـج x2",
        "🧨 تفعيـــل معـــزز الدناميـــت بوقـــت",
        "🚀 تفعيـــل معـــزز الصـــاروخ بوقـــت",
        "🌈 تفعيـــل كـــرة قـــوس قـــزح بوقـــت",
        "🔨 المطـــرقة الثاقبـــة",
        "🪛 المثقـــاب",
        "⚖️ الثقل للالـــوان",
        "🚠 المروحـــه",
        "♐ كـــرة القـــوس",
        "🧨 الدنميت",
        "🚀 الصـــاروخ",
        "↩️ رجـــــــــــــــــــــــــــــــــوع"
    }
    local menu = gg.choice(items, nil, "🎨 هدايا مطابقات الالوان")
    if not menu or menu == 1 or menu == 14 then
        currentMenuFn = showMenuB
        return showMenuB()
    end

    -- 6 أشهر بالثواني = 180 يوم × 86400 ثانية
    local SIX_MONTHS = 15552000

    if menu == 2 then
    runGroup({
        list = {{name = "🔧 تفعيل الدبل الاصفر x2",
                 values = {1835619372, 1850041445, 2037672308, 1635214674, 1816224882, 3299436}}},
        title        = "🔧 الدبل الأصفر",
        askCount     = true,
        stickersMode = true
    })

    elseif menu == 3 then
        -- 🔮 الدبل البنفسج (searchAndReplace - وقت ثابت 6 أشهر)
        searchAndReplace({
            name = "تفعيل الدبل البنفسج x2",
            icon = "🔮",
            searchNumber = "1701669204",
            checks = {{offset = -0x4, value = 0},{offset = -0x8, value = 0},{offset = 0x8, value = 1383691369},{offset = 0x14, value = 1950429784},{offset = 0x1C, value = 29556}},
            productValue = SIX_MONTHS
        })

    elseif menu == 4 then
        -- 🧨 معزز الدناميت
        searchAndReplace({
            name = "تفعيل معزز الدناميت بوقت",
            icon = "🧨",
            searchNumber = "1668571469",
            checks = {{offset = -0x8, value = 0},{offset = -0x4, value = 0},{offset = 0x8, value = 1866621549},{offset = 0x14, value = 6647145},{offset = 0x20, value = 0}},
            productValue = SIX_MONTHS
        })

    elseif menu == 5 then
        -- 🚀 معزز الصاروخ
        searchAndReplace({
            name = "تفعيل معزز الصاروخ بوقت",
            icon = "🚀",
            searchNumber = "1668571469",
            checks = {{offset = -0x8, value = 0},{offset = -0x4, value = 0},{offset = 0x8, value = 1866622318},{offset = 0x14, value = 6647145},{offset = 0x20, value = 0}},
            productValue = SIX_MONTHS
        })

    elseif menu == 6 then
        -- 🌈 كرة قوس قزح
        searchAndReplace({
            name = "تفعيل كرة قوس قزح بوقت",
            icon = "🌈",
            searchNumber = "1668571469",
            checks = {{offset = -0x4, value = 0},{offset = -0x8, value = 0},{offset = 0x8, value = 1853122663},{offset = 0x14, value = 1718511967},{offset = 0x20, value = 0}},
            productValue = SIX_MONTHS
        })

    elseif menu == 7 then
    runGroup({list = {{name = "المطرقة الثاقبة🔨", values = {1295215888, 1701604449, 1835073652, 7497069, 295108729, 120}}}, title = "🔨 المطرقة", askCount = true, stickersMode = true})
elseif menu == 8 then
    runGroup({list = {{name = "المثقاب🪛", values = {1211329824, 2053730927, 1635020399, 1852394604, 295108709, 120}}}, title = "🪛 المثقاب", askCount = true, stickersMode = true})
elseif menu == 9 then
    runGroup({list = {{name = "الثقل للالوان⚖️", values = {1446210844, 1769239141, 1282171235, 6647401, 295108709, 120}}}, title = "⚖️ الثقل", askCount = true, stickersMode = true})
elseif menu == 10 then
    runGroup({list = {{name = "المروحه🚠", values = {1379101974, 1969779557, 1701602918, 6647296, 295108709, 120}}}, title = "🚠 المروحة", askCount = true, stickersMode = true})
elseif menu == 11 then
    runGroup({list = {{name = "كرة القوس♐", values = {1379101978, 1651403105, 1631745903, 27756, 0, 0}}}, title = "♐ الكرة", askCount = true, stickersMode = true})
elseif menu == 12 then
    runGroup({list = {{name = "الدنميت🧨", values = {1110666508, 6450543, 11, 0, 2105761864, 117}}}, title = "🧨 الديناميت", askCount = true, stickersMode = true})
elseif menu == 13 then
    runGroup({list = {{name = "الصاروخ🚀", values = {1278438668, 6647401, 11, 0, 2105761864, 117}}}, title = "🚀 الصاروخ", askCount = true, stickersMode = true})
    end
end


-- ═══════════════════════════════════════════════════════════
-- 19) القوائم الرئيسية
-- ═══════════════════════════════════════════════════════════
showMenuB = function()
    currentMenuFn = showMenuB
    local menuItems = {
        "↩️ رجـــــــــــــــــــــــــــــــــوع",
        "🎁 القســـــــائم",
        "💸 الكـــاش وهدايـــا الأحـــداث",
        "🖼️ الملصقـــــــات",
        "🖼️ استبـــدال الصـــور",
        "🏙️ زينـــة المدينـــة",
        "🎨 هــدايــا مطابقــات الألــوان",
        "🏗️ الشونـــة والبنـــاء",
        "🚫 الزينـــة التـــي تسبـــب حظـــر",
        "✅ تفعيـــل التصريـــح",
        "🌾 ربـــح منتجـــات الشونـــه",
        "🏠 رجـــــــــــــــــــــــــــــــــوع",
        "❌ الخـــــــروج"
    }
    local c = gg.choice(menuItems, nil, "🔐 التصريح والاستبدال")
    if not c then return end
    if c == 1 or c == 12 then currentMenuFn = showMainMenu; return showMainMenu() end

    if c == 2 then Haie()
    elseif c == 3 then showCashMenu()
    elseif c == 4 then
    runGroup({
        list         = stickersList,
        title        = "🖼️ الملصقات",
        askCount     = false,
        stickersMode = true         -- ✅ إشعار الملصقات
    })
elseif c == 5 then
    runGroup({
        list         = picturesList,
        title        = "🖼️ الصور",
        askCount     = false,
        stickersMode = true         -- ✅ إشعار الملصقات
    })
    elseif c == 6 then showCityDecorMenu()
    elseif c == 7 then showMatchingColorGifts()
    elseif c == 8 then showBuildMenu()
    elseif c == 9 then showBanDecorMenu()
    elseif c == 10 then goldenCyihards()
    elseif c == 11 then showBarnProductsMenu()
    elseif c == 13 then os.exit() end
end

-- ═══════════════════════════════════════════════════════════
-- 🌾 قائمة ربح منتجات الشونة
-- ═══════════════════════════════════════════════════════════
showBarnProductsMenu = function()
    currentMenuFn = showBarnProductsMenu
    local items = {
        "↩️ عـــــــوده",
        "🌾 ربـــح منتجـــات الشونـــه",
        "❌ الخـــــــروج"
    }
    local c = gg.choice(items, nil, "🌾 ربح منتجات الشونه")
    if not c then return end

    if c == 1 then
        currentMenuFn = showMenuB; return showMenuB()
    elseif c == 2 then
        runGroup({
            list         = barnProductsList,
            title        = "🌾 منتجات الشونة",
            askCount     = true,        -- ✅ يسأل عن العدد
            stickersMode = false
        })
    elseif c == 3 then
        os.exit()
    end
end

showMainMenu = function()
    currentMenuFn = showMainMenu
    local items = {
        "🔐 التصريــــــــــح والاستبـــــــــدال",
        "⭐ رفـــــــع المستــــــوى",
        "💳 قســـــــــم الكـــــــــروت",
        "🏙️ تطويـــــــــــر المدينـــــــة",
        "✈️ الطائــــــــــــرة والقطـــــــــــار",
        "🚤 سبـــاق الزوارق",
        "ℹ️ حول السكربت",
        "❌ خــــــــــــــــــروج"
    }
    local c = gg.choice(items, nil, "🌟 "..SCRIPT_NAME.." 🌟")
    if not c then return end
    if c == 1 then showMenuB() elseif c == 2 then showLevelMenu() elseif c == 3 then showCardsSectionMenu()
    elseif c == 4 then cityDevelopment() elseif c == 5 then showPlaneTrainMenu() elseif c == 6 then showRaceMenu() elseif c == 7 then gg.alert(APP_NAME .. "\nالمطور: " .. DEVELOPER_NAME .. "\nالإصدار: " .. APP_VERSION .. "\nالحالة: تجريبي") elseif c == 8 then os.exit() end
end


gg.toast("⏳ جاري تجهيز الاسكربت... انتظر لحظات")

-- ═══════════════════════════════════════════════════════════
-- 📦 تحميل البيانات
-- ═══════════════════════════════════════════════════════════
loadData()
-- loadAllData()   -- ❌ معطّل (مؤشرات القطارات/الطائرة)
loadCoopCities()
-- cityMissionValue = loadCityValue() or nil   -- ❌ معطّل (سيُكتشف عند تهيئة السباق)
cooperationValue_global = loadCooperationValue() or nil

if #savedCoopCities > 0 then
    gg.toast("🏙️ " .. #savedCoopCities .. " مدينة محفوظة")
end

-- ═══════════════════════════════════════════════════════════
-- 🔄 الحلقة الرئيسية
-- ═══════════════════════════════════════════════════════════
while true do
    if gg.isVisible() then
        gg.setVisible(false)
        if currentMenuFn then currentMenuFn() else showMainMenu() end
    end
    checkAndReplace()
    if monitoringEnabled        then pcall(checkMonitoring)        end
    if productMonitoringEnabled then pcall(checkProductMonitoring) end
    gg.sleep(100)
end
-- MUBARAK_SECRET_2024
