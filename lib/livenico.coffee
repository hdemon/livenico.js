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
    new Promise (resolve, reject) ->
      request
        url: "http://flapi.nicovideo.jp/api/getflv/sm24107653"
      , (err, response, body) -> resolve qs.parse body

  getMessage: (movieInfo) ->
    (new Request).get "#{movieInfo.ms.replace 'api', 'api.json'}thread?res_from=-1000&version=20090904&thread=#{movieInfo.thread_id}"

  getMovieComment: (id) ->
    @login
      mail: @mail
      password: @password
    .then =>
      (@getFlv id).then @getMessage

  login: (args) ->
    new Promise (resolve, reject) ->
      request.post
        url: "https://secure.nicovideo.jp/secure/login?site=niconico"
        jar: j
        method: "POST"
        headers:
          "Content-Type": "application/x-www-form-urlencoded"
        body: qs.stringify
          "mail_tel": args.mail
          "password": args.password
      , (err, response, body) ->
        resolve response

class Request
  get: (args) ->
    new Promise (resolve, reject) ->
      request.get args, (error, response, body) ->
        if error
          reject error
        else
          resolve response

module.exports = Nico
