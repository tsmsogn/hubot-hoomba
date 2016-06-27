# Description
#   Assign tasks to users in random
#
# Configuration:
#   HUBOT_TASK_AGENT_ADMIN - A comma separate list of user IDs
#
# Commands:
#   hubot <user> can do <task> task - Set a task to a user
#   hubot <user> can't do <task> task - Unset a task from a user
#   hubot what tasks can <user> do - Find out what tasks a user can do
#   hubot what tasks can I do - Find out what tasks you can do
#   hubot who can do <task> task - Find out who can do the given task
#   hubot assign <task> task to a user - Assings a task to a user in random
#   hubot list tasks - List all tasks
#
# Notes:
#   * Call the method: robot.task_agent.canDoTask(msg.envelope.user,'<task>')
#   * returns bool true or false
#
#   * the 'admin' task can only be assigned through the environment variable
#   * tasks are all transformed to lower case
#
#   * The script assumes that user IDs will be unique on the service end as to
#     correctly identify a user. Names were insecure as a user could impersonate
#     a user

config =
  admin_list: process.env.HUBOT_TASK_AGENT_ADMIN

module.exports = (robot) ->

  unless config.admin_list?
    robot.logger.warning 'The HUBOT_TASK_AGENT_ADMIN environment variable not set'

  if config.admin_list?
    admins = config.admin_list.split ','
  else
    admins = []

  class TaskAgent
    isAdmin: (user) ->
      user.id.toString() in admins

    canDoTask: (user, tasks) ->
      userTasks = @userTasks(user)
      if userTasks?
        tasks = [tasks] if typeof tasks is 'string'
        for task in tasks
          return true if task in userTasks
      return false

    usersWithTask: (task) ->
      users = []
      for own key, user of robot.brain.data.users
        if @canDoTask(user, task)
          users.push(user.name)
      users

    userTasks: (user) ->
      tasks = []
      if user.tasks?
        tasks = tasks.concat user.tasks
      tasks

    select: (users, n = 1) ->
      users = @shuffle(users)
      users[0...n]

    shuffle: (array) ->
      m = array.length
      while m
        i = Math.floor(Math.random() * m--)
        [array[m], array[i]] = [array[i], array[m]]
      array

  robot.task_agent = new TaskAgent

  robot.respond /@?(.+) can do (.+) task/i, (msg) ->
    unless robot.task_agent.isAdmin msg.message.user
      msg.reply "Sorry, only admins can set tasks to users"
    else
      name = msg.match[1].trim()
      if name.toLowerCase() is 'i' then name = msg.message.user.name
      newTask = msg.match[2].trim().toLowerCase()

      unless name.toLowerCase() in ['', 'who', 'what', 'where', 'when', 'why']
        user = robot.brain.userForName(name)
        return msg.reply "#{name} does not exist" unless user?
        user.tasks or= []

        if newTask in user.tasks
          msg.reply "#{name} already can do the '#{newTask}' task."
        else
          myTasks = msg.message.user.tasks or []
          user.tasks.push(newTask)
          msg.reply "OK, #{name} can do the '#{newTask}' task."

  robot.respond /@?(.+) can(['’]t| ?not) do (.+) task/i, (msg) ->
    unless robot.task_agent.isAdmin msg.message.user
      msg.reply "Sorry, only admins can remove tasks from users."
    else
      name = msg.match[1].trim()
      if name.toLowerCase() is 'i' then name = msg.message.user.name
      newTask = msg.match[3].trim().toLowerCase()

      unless name.toLowerCase() in ['', 'who', 'what', 'where', 'when', 'why']
        user = robot.brain.userForName(name)
        return msg.reply "#{name} does not exist" unless user?
        user.tasks or= []
        myTasks = msg.message.user.tasks or []
        user.tasks = (task for task in user.tasks when task isnt newTask)
        msg.reply "OK, #{name} can't do the '#{newTask}' task."

  robot.respond /what tasks? can @?(.+) do\?*$/i, (msg) ->
    name = msg.match[1].trim()
    if name.toLowerCase() is 'i' then name = msg.message.user.name
    user = robot.brain.userForName(name)
    return msg.reply "#{name} does not exist" unless user?
    userTasks = robot.task_agent.userTasks(user)

    if userTasks.length == 0
      msg.reply "#{name} can do no tasks."
    else
      msg.reply "#{name} can do the following tasks: #{userTasks.join(', ')}."

  robot.respond /who can do (.+) task\?*$/i, (msg) ->
    task = msg.match[1].toLowerCase()
    userNames = robot.task_agent.usersWithTask(task) if task?

    if userNames.length > 0
      msg.reply "The following people can do the '#{task}' task: #{userNames.join(', ')}"
    else
      msg.reply "There are no people that can do the '#{task}' task."

  robot.respond /assign (.+) task to (a|\d+) users?$/i, (msg) ->
    unless robot.task_agent.isAdmin msg.message.user
      msg.reply "Sorry, only admins can assign tasks."
    else

      task = msg.match[1].toLowerCase()
      numberOfUser = msg.match[2]
      if numberOfUser.toLowerCase() is 'a' then numberOfUser = 1
      userNames = robot.task_agent.usersWithTask(task) if task?
  
      if userNames.length > 0
        electedUserName = robot.task_agent.select(userNames, numberOfUser)
        msg.reply "The following people is assigned to the '#{task}' task: #{electedUserName.join(', ')}"
      else
        msg.reply "There are no people that can do the '#{task}' task."

  robot.respond /list tasks/i, (msg) ->
    tasks = []
    for key, user of robot.brain.data.users
      tasks.push task for task in robot.task_agent.userTasks(user) when task not in tasks

    if tasks.length > 0
      msg.reply "The following tasks are exists: #{tasks.join(', ')}"
    else
      msg.reply "No tasks to list."
