const focusedWin = require('./')

focusedWin.on('change', win => {
  console.log('Focus change\n', JSON.stringify(win, null, 2), '\n')
})
