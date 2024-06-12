var context = this;

var runner = function (func) {
  var serializer = require('./serializer.js');
  var deserializer = require('./deserializer.js');
  var fs = require('fs');

  var content = fs.readFileSync(0).toString();
  // splits by newline and adds a trailing javascript null (maybe for bounds checking)
  content = content.trim().split(/\r\n|\r|\n/).concat(null);

  var i = 0, readline = function () { return content[i++]; };
  var print = function (s) { fs.appendFileSync('user.out', s + '\n'); };

  // I don't think it is necessary to call the function w/ this = context, but whatever.
  func.call(context, readline, print, serializer, deserializer);
}

runner = runner.bind(context);
module.exports = runner;
