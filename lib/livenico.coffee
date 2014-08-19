tough = require 'tough-cookie'
request = require "request"
Promise = require "bluebird"
qs = require 'querystring'

j = request.jar()
request = request.defaults {jar: j}

class Nico
  constructor: (args) ->
    {@mail, @password} = args

  getFlv: (id, response) ->
    new Request
      url: "http://flapi.nicovideo.jp/api/getflv/sm24107653"
    .then (response) -> Promise.resolve qs.parse response.body

  getMessage: (movieInfo) ->
    new Request
      method: "GET"
      url: "#{movieInfo.ms.replace 'api', 'api.json'}thread?res_from=-1000&version=20090904&thread=#{movieInfo.thread_id}"

  getMovieComment: (id) ->
    @login
      mail: @mail
      password: @password
    .then =>
      (@getFlv id).then @getMessage

  login: (args) ->
    new Request
      url: "https://secure.nicovideo.jp/secure/login?site=niconico"
      jar: j
      method: "POST"
      headers:
        "Content-Type": "application/x-www-form-urlencoded"
      body: qs.stringify
        "mail_tel": args.mail
        "password": args.password

class Request
  constructor: (args) ->
    return new Promise (resolve, reject) ->
      request args, (error, response, body) ->
        if error
          reject error
        else
          resolve response

module.exports = Nico
