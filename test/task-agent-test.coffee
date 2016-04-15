expect = require('chai').expect
path   = require 'path'

Robot       = require 'hubot/src/robot'
TextMessage = require('hubot/src/message').TextMessage

describe 'task-agent', ->
  robot = {}
  admin_user = {}
  task_user = {}
  anon_user = {}
  adapter = {}

  beforeEach (done) ->
    process.env.HUBOT_TASK_AGENT_ADMIN = "1"

    # Create new robot, without http, using mock adapter
    robot = new Robot null, "mock-adapter", false

    robot.adapter.on "connected", ->

      # load the module under test and configure it for the
      # robot. This is in place of external-scripts
      require("../src/task-agent")(robot)

      admin_user = robot.brain.userForId "1", {
        name: "admin-user"
        room: "#test"
      }

      task_user = robot.brain.userForId "2", {
        name: "task-user"
        room: "#test"
      }

      anon_user = robot.brain.userForId "3", {
        name: "anon-user"
        room: "#test"
      }

      adapter = robot.adapter

      done()

    robot.run()

  afterEach ->
    robot.shutdown()

  it 'anon user fails to set task', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /only admins can set tasks to users/i
      done()

    adapter.receive(new TextMessage anon_user, "hubot: task-user can do demo task")

  it 'anon user fails to remove task', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /only admins can remove tasks from users/i
      done()

    adapter.receive(new TextMessage anon_user, "hubot: task-user can't do demo task")

  it 'anon user fails to assign task', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /only admins can assign tasks/i
      done()

    adapter.receive(new TextMessage anon_user, "hubot: assign demo task to 2 users")

  it 'admin user successfully sets task', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /task-user can do the 'demo' task/i
      done()

    adapter.receive(new TextMessage admin_user, "hubot: task-user can do demo task")

  it 'admin user successfully sets task in the first-person', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /admin-user can do the 'demo' task/i
      done()

    adapter.receive(new TextMessage admin_user, "hubot: I can do demo task")

  it 'admin user successfully removes task in the first-person', (done) ->
    adapter.receive(new TextMessage admin_user, "hubot: admin-user can do demo task")

    adapter.on "reply", (envelope, strings) ->
      if strings[0].match /OK, admin-user can do the .*demo/ then return

      expect(strings[0]).to.match /can't do the 'demo' task/i
      done()

    adapter.receive(new TextMessage admin_user, "hubot: I can't do demo task")

  it 'successfully list multiple tasks of admin user', (done) ->
    adapter.receive(new TextMessage admin_user, "hubot: admin-user can do demo task")

    adapter.on "reply", (envelope, strings) ->
      if strings[0].match /OK, admin-user can do the .*demo/ then return

      expect(strings[0]).to.match /following tasks: .*demo/i
      done()

    adapter.receive(new TextMessage anon_user, "hubot: what tasks can admin-user do?")

  it 'successfully assign task to users', (done) ->
    adapter.receive(new TextMessage admin_user, "hubot: admin-user can do demo task")
    adapter.receive(new TextMessage admin_user, "hubot: task-user can do demo task")

    adapter.on "reply", (envelope, strings) ->
      if strings[0].match /OK, admin-user can do the .*demo/ then return
      if strings[0].match /OK, task-user can do the .*demo/ then return

      expect(strings[0]).to.match /following people is assigned/i
      expect(strings[0]).to.match /admin-user/i
      expect(strings[0]).to.match /task-user/i
      done()

    adapter.receive(new TextMessage admin_user, "hubot: assign demo task to 2 users")
