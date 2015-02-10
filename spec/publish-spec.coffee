path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
express = require 'express'
http = require 'http'
apm = require '../lib/apm-cli'

describe 'apm publish', ->
  [server] = []

  beforeEach ->
    spyOnToken()
    silenceOutput()

    app = express()
    server =  http.createServer(app)
    server.listen(3000)

    atomHome = temp.mkdirSync('apm-home-dir-')
    process.env.ATOM_HOME = atomHome
    process.env.ATOM_API_URL = "http://localhost:3000/api"
    process.env.ATOM_RESOURCE_PATH = temp.mkdirSync('atom-resource-path-')

  afterEach ->
    server.close()

  it "validates the engines.atom range in the package.json file", ->
    packageToPublish = temp.mkdirSync('apm-test-package-')
    metadata =
      name: 'test'
      version: '1.0.0'
      engines:
        atom: '><>'
    fs.writeFileSync(path.join(packageToPublish, 'package.json'), JSON.stringify(metadata))
    process.chdir(packageToPublish)
    callback = jasmine.createSpy('callback')
    apm.run(['publish'], callback)

    waitsFor 'waiting for publish to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0].message).toBe 'The Atom engine range is invalid: ><>'

  it "validates the dependency semver ranges in the package.json file", ->
    packageToPublish = temp.mkdirSync('apm-test-package-')
    metadata =
      name: 'test'
      version: '1.0.0'
      engines:
        atom: '1'
      dependencies:
        foo: '^^'
    fs.writeFileSync(path.join(packageToPublish, 'package.json'), JSON.stringify(metadata))
    process.chdir(packageToPublish)
    callback = jasmine.createSpy('callback')
    apm.run(['publish'], callback)

    waitsFor 'waiting for publish to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0].message).toBe 'The foo dependency range is invalid: ^^'

  it "validates the dev dependency semver ranges in the package.json file", ->
    packageToPublish = temp.mkdirSync('apm-test-package-')
    metadata =
      name: 'test'
      version: '1.0.0'
      engines:
        atom: '1'
      dependencies:
        foo: '^5'
      devDependencies:
        bar: '1,3'
    fs.writeFileSync(path.join(packageToPublish, 'package.json'), JSON.stringify(metadata))
    process.chdir(packageToPublish)
    callback = jasmine.createSpy('callback')
    apm.run(['publish'], callback)

    waitsFor 'waiting for publish to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0].message).toBe 'The bar dev dependency range is invalid: 1,3'
