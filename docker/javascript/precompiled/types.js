; (function () {
  let serializer = require('./serializer.js');

  var types = {};
  module.exports = types;

  const inspect = Symbol.for('nodejs.util.inspect.custom');

  // ListNode
  types.ListNode = function ListNode(val, next) {
    this.val = (val===undefined ? 0 : val);
    this.next = (next===undefined ? null : next);
  };

  types.ListNode.prototype[inspect] = function (depth, opts) {
    return serializer.serializeList(this);
  }

  // TreeNode
  types.TreeNode = function TreeNode(val, left, right) {
    this.val = (val===undefined ? 0 : val);
    this.left = (left===undefined ? null : left)
    this.right = (right===undefined ? null : right)
  };

  types.TreeNode.prototype[inspect] = function (depth, opts) {
    return serializer.serializeTree(this);
  }

  // NestedInteger
  types.NestedInteger = function NestedInteger(val) {
    this._integer = (typeof val === 'undefined') ? null : val;
    this._list = [];

    this.isInteger = function() {
      return this._integer !== null;
    };

    this.getInteger = function() {
      return this._integer;
    };

    this.setInteger = function(i) {
      this._integer = i;
    };

    this.getList = function() {
      return this._list;
    };

    this.add = function(ni) {
      this._list.push(ni);
      this._integer = null;
    };
  };

  types.NestedInteger.prototype[inspect] = function (depth, opts) {
    return serializer.serializeNestedInteger(this);
  }

  types.NestedInteger.token_to_nested_integer = function(token) {
    var root = new types.NestedInteger();

    if(typeof token === "number") {
      root.setInteger(token);
    } else if(typeof token === "object") {
      for(var i = 0; i < token.length; i++) {
        root.add(types.NestedInteger.token_to_nested_integer(token[i]));
      }
    }
    return root;
  };

  types.NestedInteger.deserialize = function(s) {
    return types.NestedInteger.token_to_nested_integer(JSON.parse(s));
  };

}());
