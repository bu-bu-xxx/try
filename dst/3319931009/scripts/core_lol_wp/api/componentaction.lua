-- @lan: _开头的方法是内部方法,一般来说不要在外部调用
---@diagnostic disable: lowercase-global, undefined-global, trailing-space

---@class api_componentaction # 组件动作 API
local dst_lan = {}

---comment
---@param data_tbl table
---@return table # actions
---@return table # componentactions table
function dst_lan:_fix_tbl(data_tbl)
    local fixed_actions = {}
    local fixed_component_actions = {}

    for _,item in pairs(data_tbl) do
        local pal = item.type .. item.component
        if fixed_component_actions[pal] == nil then
            fixed_component_actions[pal] = {
                type = item.type,
		        component = item.component,
                tests = {
                    {
                        action = item.id,
                        testfn = item.testfn,
                    },
                },
            }
        else
            table.insert(fixed_component_actions[pal].tests,{
                action = item.id,
                testfn = item.testfn,
            })
        end
        table.insert(fixed_actions,{
            id = item.id,
            str = item.str,
            fn = item.fn,
            state = item.state,
            actiondata = item.actiondata,
            noclient = item.noclient or false,
        })
    end
    return fixed_actions,fixed_component_actions
end


function dst_lan:registActions(data_tbl)
    local fixed_actions,fixed_component_actions = self:_fix_tbl(data_tbl)

    for _,act in pairs(fixed_actions) do
        local addaction = AddAction(act.id,act.str,act.fn)
        if act.actiondata then
            for k,v in pairs(act.actiondata) do
                addaction[k] = v
            end
        end

        AddStategraphActionHandler('wilson',GLOBAL.ActionHandler(addaction, act.state))
        if not act.noclient then
            AddStategraphActionHandler('wilson_client',GLOBAL.ActionHandler(addaction,act.state))
        end
    end

    for _,v in pairs(fixed_component_actions) do
        local testfn = function(...)
            local actions = GLOBAL.select(v.type=='POINT' and -3 or -2,...)
            for _,data in pairs(v.tests) do
                if data and data.testfn and data.testfn(...) then
                    data.action = string.upper(data.action)
                    table.insert(actions,GLOBAL.ACTIONS[data.action])
                end
            end
        end
        AddComponentAction(v.type, v.component, testfn)
    end
end

function dst_lan:main(data_tbl)
    self:registActions(data_tbl)
end

return dst_lan
