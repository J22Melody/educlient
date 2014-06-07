mongoose = require 'mongoose'

Schema = mongoose.Schema
mongoose.connect 'mongodb://localhost'

StudentSchema = new Schema
  name: { type: String, required: true }
  pass: { type: String, required: true }
  classs: [ ClassSchema ]

ClassSchema = new Schema
  name: { type: String, required: true }
  mentor: { type: String, required: true }
  place: { type: String, required: true }
  credit: { type: String, required: true }
  period: { type: String, required: true }

exports.Student = mongoose.model 'Student', StudentSchema
exports.Class = mongoose.model 'Class', ClassSchema
