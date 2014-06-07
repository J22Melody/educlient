# require
express = require 'express'
request = require 'request'
xml2json = require 'xml2json'
toJson = (x) -> JSON.parse xml2json.toJson(x)
toXml = (x) -> xml2json.toXml JSON.stringify(x)
db = require './db'
Student = db.Student
Class = db.Class
cookieParser = require 'cookie-parser'
session = require 'express-session'

# config
app = express()

app.use cookieParser()
app.use session(
  secret: "keyboard cat"
  proxy: true # if you do SSL outside of node.
  cookie: {
    expires: new Date(Date.now() + 60 * 100000),
    maxAge: 60*100000
  }
)

app.use (require 'body-parser')()

app.set "views", "./views"
app.set "view engine", "jade"

remoteUrl = "http://vps.jiangzifan.com:3002"

# common request handle
app.get '*', (req, res, next) ->
  res.locals.req = req
  next()

checkAuth = (req, res, next) ->
  if not req.session.name
    res.redirect '/login'
  else
    next()

app.get '/login', (req, res) ->
  res.render "login"

app.post '/login', (req, res) ->
  data = req.body
  Student.findOne data, (err, doc) ->
    if doc
      req.session.name = data.name
      res.redirect '/'
    else
      res.redirect '/login'

app.get "/logout", checkAuth , (req, res) ->
  delete req.session.name
  res.redirect "/login"

app.get '/', checkAuth, (req, res) ->
  res.render "index"

app.get '/init', checkAuth, (req, res) ->
  # 数据初始化
  record = new Student {name: "黄欣", pass: "123"}
  record.save()
  record = new Class {name: "中国现当代文学名著研讨", mentor: "王彬彬（教授）", place: "仙二-111", credit: "2", period: "12"}
  record.save()
  record = new Class {name: "中国古代文学名著研讨", mentor: "李琛博", place: "仙二-121", credit: "2", period: "16"}
  record.save()
  record = new Class {name: "大学语文", mentor: "揭英泽", place: "仙二-114", credit: "3", period: "18"}
  record.save()
  record = new Class {name: "阅读与写作", mentor: "李青翔", place: "仙二-111", credit: "6", period: "10"}
  record.save()
  res.render "index"

app.get '/selectClass', checkAuth, (req, res) ->
  desSysId = req.query.desSysId or 'C'
  # 本院系选课
  if desSysId is 'C'
    Class.find {}, (err, doc) ->
      courses = [{
        'id': course._id
        'title': course.name
        'teacher': course.mentor
        'place': course.place
        'credit': course.credit
        'period': course.period
      } for course in doc][0]
      Student.findOne {name: req.session.name}, (err, doc) ->
        selected = (JSON.stringify(oneClass._id) for oneClass in doc.classs)
        for course in courses
          if JSON.stringify(course.id) in selected
            course.selected = true
          else
            course.selected = false
        res.render "selectClass", {'courses': courses}
  # 跨院系选课
  else
    request {url: remoteUrl + "/courses/" + desSysId, qs: {'srcSysId': 'C','stuId': req.session.name}}, (error, response, body) ->
      data = toJson body
      res.render "selectClass", {"courses": data.courses.course}

app.get '/select/:desSysId/:courseId', checkAuth, (req, res) ->
  # 本院系选课
  if req.params.desSysId in ['C','undefined']
    Student.findOne {name: req.session.name}, (err, doc) ->
      stu = doc
      Class.findOne {_id: req.params.courseId}, (err, doc) ->
        stu.classs[stu.classs.length] = doc
        id = stu._id
        newStu = {
          name: stu.name
          pass: stu.pass
          classs: stu.classs
        }
        stu = newStu
        Student.update {_id: id}, stu , (err, doc) ->
          res.redirect '/selectClass?desSysId=C'
  # 跨院系选课
  else
    param = {'srcSysId': 'C', 'stuId': req.session.name, 'desSysId': req.params.desSysId, 'courseId': req.params.courseId }
    request {method: "POST", url: remoteUrl + "/select", form: param}, (error, response, body) ->
      res.redirect '/selectClass?desSysId=' + req.params.desSysId

app.get '/unselect/:desSysId/:courseId', checkAuth, (req, res) ->
  # 本院系选课
  if req.params.desSysId in ['C','undefined']
    courseId = JSON.stringify(req.params.courseId)
    Student.findOne {name: req.session.name}, (err, doc) ->
      stu = doc
      classsCopy = stu.classs[..]
      for oneClass,index in classsCopy
        if JSON.stringify(oneClass._id) is courseId
          stu.classs.splice index,1
      id = stu._id
      newStu = {
        name: stu.name
        pass: stu.pass
        classs: stu.classs
      }
      stu = newStu
      Student.update {_id: id}, stu , (err, doc) ->
        res.redirect '/selectClass?desSysId=C'
  # 跨院系选课
  else
    param = {'srcSysId': 'C', 'stuId': req.session.name, 'desSysId': req.params.desSysId, 'courseId': req.params.courseId }
    request {method: "POST", url: remoteUrl + "/unselect", form: param}, (error, response, body) ->
      res.redirect '/selectClass?desSysId=' + req.params.desSysId

# api request handle
app.get '/classes.xml', (req, res) ->
  Class.find {}, (err, doc) ->
    data = {'courses': {'course': doc}}
    res.send toXml(data)

# start server
server = app.listen 3005, ->
  console.log 'Listening on port %d', server.address().port
