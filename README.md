应用集成作业
教务系统集成服务器 by coffee+nodejs+expressjs+mongoose

API如下：

###  跨院系获取课程列表  GET  /courses/:desSysId  

desSysId为你所请求的院系系统id，规定三个系统分别为A、B、C
可选get参数：stuId为当前登录你的系统的学生Id，srcSysId为你的系统Id
如果附带get参数则会顺带返回当前登录学生对列表中每个课程的选课情况
示例：/course/B?stuId=250&srcSysId=A

### 跨院系选课  POST  /select

必填post参数：srcSysId为你的系统Id，desSysId为对方系统Id，stuId为学生Id，courseId为课程Id


### 跨院系退选  POST  /unselect

必填post参数：srcSysId为你的系统Id，desSysId为对方系统Id，stuId为学生Id，courseId为课程Id
