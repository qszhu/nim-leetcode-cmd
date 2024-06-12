; (function () {

  var types = require('./types.js');
  var Queue = require('./queue.js');
  var deserializer = {};

  module.exports = deserializer;

  // Won't use global ones since user may modify them
  var ListNode = types.ListNode;
  var TreeNode = types.TreeNode;
  var NestedInteger = types.NestedInteger;

  deserializer.toArray = function (f, line) {
    return JSON.parse(line).map(
        function (x) { return f(JSON.stringify(x)); }
    );
  }

  deserializer.to2dArray = function (f, line) {
      return JSON.parse(line).map(
          function (a) { return deserializer.toArray(f, JSON.stringify(a)); }
      );
  }

  deserializer.toBoolean = function (line) {
    return JSON.parse(line);
  }

  // deserialize function
  deserializer.toInteger = function (line) {
    return JSON.parse(line);
  }

  deserializer.toDouble = function (line) {
    return JSON.parse(line);
  }

  deserializer.toCharacter = function (line) {
    return JSON.parse(line);
  }

  deserializer.toString = function (line) {
    return JSON.parse(line);
  }

  deserializer.toBooleanArray = function (line) {
    return JSON.parse(line);
  }

  deserializer.toIntegerArray = function (line) {
    return JSON.parse(line);
  }

  deserializer.toDoubleArray = function (line) {
    return JSON.parse(line);
  }

  deserializer.toDouble2dArray = function (line) {
    return JSON.parse(line);
  }

  deserializer.toInteger2dArray = function (line) {
    return JSON.parse(line);
  }

  deserializer.toCharacterArray = function (line) {
    return JSON.parse(line);
  }

  deserializer.toCharacter2dArray = function (line) {
    return JSON.parse(line);
  }

  deserializer.toStringArray = function (line) {
    return JSON.parse(line);
  }

  deserializer.toStringSet = function (line) {
    return new Set(JSON.parse(line));
  }

  deserializer.toString2dArray = function (line) {
    return JSON.parse(line);
  }

  var _arrayToList = function (nums) {
    var head = new ListNode();
    nums.reduce(function (x, y) { return (x.next = new ListNode(y)); }, head);
    return head.next;
  };

  deserializer.toList = function (line) {
    return _arrayToList(JSON.parse(line));
  }

  deserializer.toListArray = function (line) {
    return JSON.parse(line).map(_arrayToList);
  }

  var _arrayToTree = function (Node, tokens) {
    if (tokens.length == 0) return null;
    var nodes = tokens.map(function (x) {
      if (x === null) return null; else return new Node(Number(x));
    });
    var head = nodes.shift();
    var queue = new Queue();
    var enqueue = function (n) {
      queue.enqueue([n, 'left']);
      queue.enqueue([n, 'right']);
    };
    enqueue(head);
    nodes.forEach(function (n) {
      var p = queue.dequeue();
      p[0][p[1]] = n;
      if (n) enqueue(n);
    });
    return head;
  };

  var deserialize_tree = function (Node, line) {
    var tokens = JSON.parse(line);
    return _arrayToTree(Node, tokens);
  };

  // es6 isn't supported everywhere yet? so can't use arrow functions :/
  deserializer.toTree = function (line) { return deserialize_tree(TreeNode, line) };

  deserializer.toTreeArray = function (line) {
    return JSON.parse(line).map(
        function(tokens) { return _arrayToTree(TreeNode, tokens); }
    );
  };

  deserializer.toNestedInteger = function (line) {
    return NestedInteger.deserialize(line);
  };

  deserializer.toNestedIntegerArray = function (line) {
    var ni = deserializer.toNestedInteger(line);
    return ni.getList();
  };

}());
