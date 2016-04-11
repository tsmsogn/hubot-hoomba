# Hubot: hubot-task-agent

[![Build Status](https://travis-ci.org/tsmsogn/hubot-task-agent.svg?branch=master)](https://travis-ci.org/tsmsogn/hubot-task-agent)

Assign tasks to users in random

See [`src/task-agent.coffee`](src/task-agent.coffee) for full documentation.

## Installation

Add **hubot-task-agent** to your `package.json` file:

```
npm install --save hubot-task-agent
```

Add **hubot-task-agent** to your `external-scripts.json`:

```json
["hubot-task-agent"]
```

Run `npm install`

## Sample Interaction

```
user1>> hubot user1 can do cleaning task
hubot>> OK, user1 can do the 'cleaning' task.
user1>> hubot what tasks can user1 do?
hubot>> user1 can do the following tasks: cleaning.
user1>> hubot user2 can do cleaning task
hubot>> OK, user2 can do the 'cleaning' task.
user1>> hubot who can do cleaning task?
hubot>> The following people can do the 'cleaning' task: user1, user2
user1>> hubot assign cleaning task to a user
hubot>> The following people is assigned to the 'cleaning' task: user1
```
