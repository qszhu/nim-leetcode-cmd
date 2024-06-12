; (function () {

  var serializer = {};

  module.exports = serializer;

  var types = require('./types.js');
  var Queue = require('./queue.js');

  // Won't use global ones since user may modify them
  var ListNode = types.ListNode;
  var TreeNode = types.TreeNode;
  var NestedInteger = types.NestedInteger;

  serializer.serialize = function(obj, typestr) {
    try {
      if (obj === undefined) return "undefined";
      if (typestr.startsWith('list<') && typestr.endsWith('>')) return serializer.serializeArray(obj, typestr.slice(5, -1));
      if (typestr.endsWith("[]")) return serializer.serializeArray(obj, typestr.slice(0, -2));
      if (typestr === 'void') return serializer.serializeVoid(obj);
      if (typestr === 'integer') return serializer.serializeInteger(obj);
      if (typestr === 'long') {
        if (!Number.isSafeInteger(obj)) {
            throw new Error("Error when serializing long: " + obj + " isn't a JavaScript safe integer");
        }
        return serializer.serializeInteger(obj);
      }
      if (typestr === 'double') return serializer.serializeDouble(obj);
      if (typestr === 'boolean') return serializer.serializeBoolean(obj);
      if (typestr === 'character') return serializer.serializeChar(obj);
      if (typestr === 'string') return serializer.serializeString(obj);
      if (typestr === 'ListNode') return serializer.serializeList(obj);
      if (typestr === 'TreeNode') return serializer.serializeTree(obj);
      if (typestr === 'NestedInteger') return serializer.serializeNestedInteger(obj);
      throw new Error('value of expected type ' + typestr + ' could not be serialized');
    } catch (err) {
      throw new TypeError(err.message);
    }

  }

  serializer.serializeInteger = function(o) {
    return Number(o).toFixed(0);
  }

  serializer.serializeDouble = function (o) {
    return Number(o).toFixed(5);
  }

  serializer.serializeBoolean = function (o) {
    if (o ==/* not typo */ false) return 'false';
    return 'true';
  }

  serializer.serializeChar = function (o) {
    return JSON.stringify(o);
  }

  serializer.serializeString = function (o) {
    return JSON.stringify(o);
  }

  //WARNING: assumes that the array cannot be null
  serializer.serializeArray = function (o, typestr) {
    return '[' + o.map(function (x) {return serializer.serialize(x, typestr)}).join(',') + ']';
  }

  serializer._hasListCycle = function (u) {
    var set = new Set();
    while (u !== null) {
        if (set.has(u)) {
            return true;
        }
        set.add(u);
        u = u.next;
    }
    return false;
  }

  serializer.serializeList = function (o, serobj) {
    if (o === null) return '[]';
    if (serializer._hasListCycle(o)) return 'Error - Found cycle in the ListNode';

    var vals = [];
    for (; o; o = o.next) vals.push(o.val);
    return '[' + vals.map(function (x) { return serializer.serialize(x, 'integer') }).join(',') + ']';
  }

  serializer._hasTreeCycleHelper = function (u, set) {
    if (u === null) {
        return false;
    }

    if (set.has(u)) {
        return true;
    }

    set.add(u);
    var cycle_exists = serializer._hasTreeCycleHelper(u.left, set) || serializer._hasTreeCycleHelper(u.right, set);
    set.delete(u);
    return cycle_exists;
  }

  serializer._hasTreeCycle = function (u) {
    return serializer._hasTreeCycleHelper(u, new Set());
  }


  serializer.serializeTree = function (o) {
    if (o === null) return '[]';
    if (serializer._hasTreeCycle(o)) return 'Error - Found cycle in the TreeNode';

    var queue = new Queue();
    queue.enqueue(o);
    var ret = [], count = 1, n;
    while (count) {
      n = queue.dequeue();
      if (n === null) ret.push('null');
      else {
        count--;
        ret.push(serializer.serialize(n.val, 'integer'));
        queue.enqueue(n.left);
        queue.enqueue(n.right);
        if (n.left) count++;
        if (n.right) count++;
      }
    }
    return '[' + ret.join(',') + ']';
  }

  serializer.serializeNestedInteger = function (ni) {
    if(ni.isInteger()) {
      return serializer.serialize(ni.getInteger(), 'integer');
    }
    else {
      return '[' + ni.getList().map(function (x) {return serializer.serialize(x, 'NestedInteger')}).join(',') + ']'
    }
  }

}());
