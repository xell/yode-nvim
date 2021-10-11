local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local h = require('yode-nvim.helper')
local layout = storeBundle.layout

local eq = assert.are.same

describe('basic mosaic layout', function()
    local fileBufferId = 1
    local seditor1 = 2
    local seditor2 = 3
    local seditor3 = 4
    local seditor1Win = 1002
    local seditor2Win = 1003
    local seditor3Win = 1004

    it('create floating seditors', function()
        eq({ seditors = {}, layout = { tabs = {} } }, store.getState())

        vim.cmd('e ./testData/basic.js')

        -- seditor 1
        vim.cmd('3,9YodeCreateSeditorFloating')

        tutil.assertBufferContentString([[
const getSeditorWidth = async (nvim) => {
    if (!mainWindowWidth) {
        mainWindowWidth = Math.floor((await nvim.getOption('columns')) / 2)
    }

    return mainWindowWidth
}]])

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())
        eq({
            id = 1,
            config = {},
            data = {},
            name = 'mosaic',
            isDirty = false,
        }, R.omit(
            { 'windows' },
            store.getState().layout.tabs[1]
        ))
        eq(
            {
                {
                    y = 1,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    relative = 'editor',
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )

        vim.cmd('wincmd h')
        eq(fileBufferId, vim.fn.bufnr('%'))

        -- seditor 2
        vim.cmd('11,25YodeCreateSeditorFloating')

        tutil.assertBufferContentString([[
async function createSeditor(nvim, text, row, height) {
    const buffer = await nvim.createBuffer(false, false)

    const foo = 'bar'
    const width = await getSeditorWidth(nvim)
    const window = await nvim.openWindow(buffer, true, {
        relative: 'editor',
        row,
        col: width,
        width,
        height: height,
        focusable: true,
    })
    return window
}]])

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:3.js',
        }, tutil.getHumanBufferList())
        eq(
            {
                {
                    y = 1,
                    height = 15,
                    id = seditor2Win,
                    bufId = seditor2,
                    relative = 'editor',
                    data = { visible = true },
                },
                {
                    y = 17,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    relative = 'editor',
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )

        vim.cmd('wincmd h')
        eq(fileBufferId, vim.fn.bufnr('%'))

        -- seditor 3
        vim.cmd('49,58YodeCreateSeditorFloating')

        tutil.assertBufferContentString([[
plugin.registerCommand(
    'YodeCreateSeditor',
    async () => {
        await createSeditor(nvim, '1111', 0, 20 == 50)

        await createSeditor(nvim, '2222', 21, 10)
        await createSeditor(nvim, '3333', 32, 15)
    },
    { sync: false }
)]])

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:3.js',
            [seditor3] = 'yode://./testData/basic.js:4.js',
        }, tutil.getHumanBufferList())
        eq(
            {
                {
                    y = 1,
                    height = 10,
                    id = seditor3Win,
                    bufId = seditor3,
                    relative = 'editor',
                    data = { visible = true },
                },
                {
                    y = 12,
                    height = 15,
                    id = seditor2Win,
                    bufId = seditor2,
                    relative = 'editor',
                    data = { visible = true },
                },
                {
                    y = 28,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    relative = 'editor',
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )
    end)

    it('selecting window by some id works', function()
        eq(
            {
                id = seditor1Win,
                bufId = seditor1,
            },
            R.pick(
                { 'id', 'bufId' },
                layout.selectors.getWindowBySomeId(vim.api.nvim_get_current_tabpage(), {
                    bufId = seditor1,
                })
            )
        )

        eq(
            {
                id = seditor1Win,
                bufId = seditor1,
            },
            R.pick(
                { 'id', 'bufId' },
                layout.selectors.getWindowBySomeId(vim.api.nvim_get_current_tabpage(), {
                    winId = seditor1Win,
                })
            )
        )
    end)

    it("can't switch buffer to non seditor buffer in floating window", function()
        eq(seditor3Win, vim.fn.win_getid())
        eq(seditor3, vim.fn.bufnr('%'))

        vim.cmd('b ' .. fileBufferId)
        eq(seditor3Win, vim.fn.win_getid())
        eq(seditor3, vim.fn.bufnr('%'))
    end)

    it('shifting windows', function()
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 1,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 12,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 28,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinDown')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 1,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 17,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 28,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinDown')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 1,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 17,
                height = 7,
                id = seditor1Win,
            },
            {
                y = 25,
                height = 10,
                id = seditor3Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinTop')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 1,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 12,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 28,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinBottom')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 1,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 17,
                height = 7,
                id = seditor1Win,
            },
            {
                y = 25,
                height = 10,
                id = seditor3Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinUp')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 1,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 17,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 28,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinUp')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 1,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 12,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 28,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinUp')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 1,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 17,
                height = 7,
                id = seditor1Win,
            },
            {
                y = 25,
                height = 10,
                id = seditor3Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinDown')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 1,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 12,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 28,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))
    end)

    it('should use tab handles, not tab numbers', function()
        vim.cmd('tabnew')
        vim.cmd('tabclose')
        vim.cmd('tabnew')
        vim.cmd('b ' .. seditor1)
        vim.cmd('YodeCloneCurrentIntoFloat')

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:3.js',
            [seditor3] = 'yode://./testData/basic.js:4.js',
            [5] = '',
            [6] = '',
        }, tutil.getHumanBufferList())
        -- with tab numbers it would be {1, 2}
        eq({ 1, 3 }, R.keys(store.getState().layout.tabs))
    end)

    it('tab close is handled', function()
        vim.cmd('tabclose')
        eq({ 1 }, R.keys(store.getState().layout.tabs))

        -- cleanup
        vim.cmd('bd 5')
        vim.cmd('bd 6')
    end)

    it('changing content height, changes layout', function()
        -- TODO not possible to test atm
    end)

    it('delete floating buffer', function()
        vim.cmd('tab split')
        vim.cmd('b ' .. seditor2)
        vim.cmd('YodeCloneCurrentIntoFloat')
        vim.cmd('b ' .. seditor1)
        vim.cmd('YodeCloneCurrentIntoFloat')
        vim.cmd('b ' .. fileBufferId)
        vim.cmd('wincmd w')
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:3.js',
            [seditor3] = 'yode://./testData/basic.js:4.js',
        }, tutil.getHumanBufferList())
        eq(seditor1, vim.fn.bufnr('%'))
        eq({ 1, 4 }, R.keys(store.getState().layout.tabs))
        eq({ [1] = false, [4] = false }, R.pluck('isDirty', store.getState().layout.tabs))
        eq(
            { seditor3, seditor2, seditor1 },
            R.pluck('bufId', store.getState().layout.tabs[1].windows)
        )
        eq({ seditor1, seditor2 }, R.pluck('bufId', store.getState().layout.tabs[4].windows))

        vim.cmd('bd')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq({ 1, 4 }, R.keys(store.getState().layout.tabs))
        eq({ [1] = true, [4] = false }, R.pluck('isDirty', store.getState().layout.tabs))
        eq({ seditor3, seditor2 }, R.pluck('bufId', store.getState().layout.tabs[1].windows))
        eq({ seditor2 }, R.pluck('bufId', store.getState().layout.tabs[4].windows))

        vim.cmd('tabnext')
        eq({ [1] = false, [4] = false }, R.pluck('isDirty', store.getState().layout.tabs))
        vim.cmd('tabnext')

        vim.cmd('wincmd w')
        eq(seditor2, vim.fn.bufnr('%'))

        vim.cmd('bd')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq({ 1, 4 }, R.keys(store.getState().layout.tabs))
        eq({ seditor3 }, R.pluck('bufId', store.getState().layout.tabs[1].windows))
        eq({}, R.pluck('bufId', store.getState().layout.tabs[4].windows))

        -- TODO change window layout before deleting last buffer, when we have
        -- more of them. Should keep tab state. Assert layout name is still
        -- 'the other layout'. When user floats the next window, his selected
        -- layout should be still active!
        eq('mosaic', store.getState().layout.tabs[4].name)
    end)
end)