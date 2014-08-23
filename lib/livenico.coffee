net = require 'net'
tough = require 'tough-cookie'
request = require "request"
Promise = require "bluebird"
qs = require 'querystring'
cheerio = require 'cheerio'
require('source-map-support')

j = request.jar()
request = request.defaults {jar: j}

class Nico
  constructor: (args) ->
    @session = null
    {@mail, @password} = args

  getPlayerStatus: (id) ->
    new Request
      url: "http://live.nicovideo.jp/api/getplayerstatus?v=#{id}"
    .then (response) -> Promise.resolve response.body

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

  getLiveMovieCommentXmlBuffers: (playerStatusHash, options={when:''}) ->
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
          resolve result.join('').toString()

  getMovieCommentXml: (id) ->
    @login()
      .then => (@getFlv id)
      .then @getMessage

  getLiveMovieCommentXml: (id, options) ->
    @login()
      .then => (@getPlayerStatus id)
      .then(@parsePlayerStatus)
      .then (playerStatus) =>
        return Promise.reject playerStatus.code if playerStatus.status == 'fail'
        return Promise.reject "'when' option must be later than live movie's open time." if playerStatus.open_time >= options.when
        @getLiveMovieCommentXmlBuffers playerStatus, options
      .catch Promise.reject

  parsePlayerStatus: (playerStatus) ->
    $ = cheerio.load playerStatus
    getplayerstatus = $('getplayerstatus')

    if getplayerstatus.find("error").html()
      addr = port = thread = user_id = null
      code = getplayerstatus.find('code').text()
    else
      addr = getplayerstatus.find('ms addr').text()
      port = getplayerstatus.find('ms port').text()
      thread = getplayerstatus.find('ms thread').text()
      user_id = getplayerstatus.find('user user_id').text()
      open_time = Number getplayerstatus.find('open_time').text()
      code = null

    status = getplayerstatus.attr('status')

    {addr, port, thread, user_id, open_time, status, code}

  login: ->
    return Promise.resolve() if @hasAvailableSession @session
    new Request
      url: "https://secure.nicovideo.jp/secure/login?site=niconico"
      jar: j
      method: "POST"
      headers:
        "Content-Type": "application/x-www-form-urlencoded"
      body: qs.stringify
        "mail_tel": @mail
        "password": @password
    .then (result) =>
      @session ?= j._jar.store.idx['nicovideo.jp']['/'].user_session
      result

  hasAvailableSession: (session) ->
    @session && @session.toString().match /user_session\=user_session_\d*/

class Request
  constructor: (args) ->
    return new Promise (resolve, reject) ->
      request args, (error, response, body) ->
        if error
          reject error
        else
          resolve response

module.exports = Nico
