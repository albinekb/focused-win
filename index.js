const execa = require('execa')
const EventEmitter = require('events')
const { join: pathJoin } = require('path')

const emitter = new EventEmitter()

let child
emitter.on('removeListener', () => {
  if (emitter.listenerCount('change') === 0 && child) {
    child.kill()
    child = null
  }
})

emitter.on('newListener', () => {
  if (child) {
    return
  }

  child = execa(pathJoin(__dirname, 'build', 'focused-win'))
  child.catch(error => {
    if (!error.killed) {
      emitter.emit('error', error)
    }
  })

  child.stdout.on('data', (data) => {
    const string = data.toString()

    try {
      const json = JSON.parse(string)
      const parsed = Object.assign({}, json, {
        app: Buffer.from(json.app, 'base64').toString('utf8'),
        title: Buffer.from(json.title, 'base64').toString('utf8')
      })

      emitter.emit('change', parsed)
    } catch (error) {
      emitter.emit('error', error)
    }
  })
})

module.exports = emitter
