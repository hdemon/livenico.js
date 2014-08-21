net = require 'net'
tough = require 'tough-cookie'
request = require "request"
Promise = require "bluebird"
qs = require 'querystring'

j = request.jar()
request = request.defaults {jar: j}

class Nico
  constructor: (args) ->
    {@mail, @password} = args

  getPlayerStatus: (id) ->
    new Request
      url: "http://live.nicovideo.jp/api/getplayerstatus?v=#{id}"
    .then (response) ->
      Promise.resolve response.body

  getFlv: (id) ->
    new Request
      url: "http://flapi.nicovideo.jp/api/getflv/#{id}"
    .then (response) -> Promise.resolve qs.parse response.body

  getWeyBackKey: (thread) ->
    new Request
      url: "http://watch.live.nicovideo.jp/api/getwaybackkey?thread=#{thread}"
    .then (response) -> Promise.resolve response.body.replace /waybackkey\=/, ''

  getMessage: (movieInfo) ->
    new Request
      method: "GET"
      url: "#{movieInfo.ms.replace 'api', 'api.json'}thread?res_from=-1000&version=20090904&thread=#{movieInfo.thread_id}"

  getLiveMovieMessage: (playerStatusHash, options={when:''}) ->
    {addr, port, thread, user_id} = playerStatusHash

    new Promise (resolve, reject) =>
      (@getWeyBackKey thread).then (weyBackKey) ->
        result = []
        socket = new net.Socket({ writable: true, readable: true })
        socket.connect port, addr
        socket.on "connect", ->
          socket.write "<thread thread=\"#{thread}\" version=\"20061206\" res_from=\"-1000\" when=\"#{options.when}\" waybackkey=\"#{weyBackKey}\" user_id=\"#{user_id}\" scores=\"1\" />\0"
          socket.end()
        socket.on "data", (data) ->
          result.push data
        socket.on "end", ->
          resolve result

  getMovieComment: (id) ->
    @login()
      .then => @getFlv id
      .then @getMessage

  getLiveMovieComment: (id, options) ->
    @login()
      .then => @getPlayerStatus id
      .then (playerStatus) => @getLiveMovieMessage (@parsePlayerStatus playerStatus), options

  getAllLiveMovieComment: (id) ->
    @login().then =>
      (@getPlayerStatus id).then (playerStatus) =>
        @getLiveMovieMessage @parsePlayerStatus playerStatus

  parsePlayerStatus: (playerStatus) ->
    addr = (playerStatus.match /<addr>[a-z0-9.]*/)[0].replace /<addr>/, ''
    port = (playerStatus.match /<port>\d*/)[0].replace /<port>/, ''
    thread = (playerStatus.match /<thread>\d*/)[0].replace /<thread>/, ''
    user_id = (playerStatus.match /<user_id>\d*/)[0].replace /<user_id>/, ''

    {addr, port, thread, user_id}

  login: ->
    new Request
      url: "https://secure.nicovideo.jp/secure/login?site=niconico"
      jar: j
      method: "POST"
      headers:
        "Content-Type": "application/x-www-form-urlencoded"
      body: qs.stringify
        "mail_tel": @mail
        "password": @password

class Request
  constructor: (args) ->
    return new Promise (resolve, reject) ->
      request args, (error, response, body) ->
        if error
          reject error
        else
          resolve response

module.exports = Nico
