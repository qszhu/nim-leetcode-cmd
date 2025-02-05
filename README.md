[![build](https://github.com/qszhu/nim-leetcode-cmd/actions/workflows/build.yaml/badge.svg)](https://github.com/qszhu/nim-leetcode-cmd/actions/workflows/build.yaml)

# Warning

Experimental. USE AT YOUR OWN RISK.

在正式比赛中使用的风险未知.

# Getting started

* Login in your preferred browser (Chrome/Edge/Firefox).
* Close the browser and make sure no browser processes are running.
* In a new folder, run `nlcc`:

```bash
$ nlcc
Choose browser [firefox|chrome|edge] (chrome): [Enter]
Browser profile path (/Users/whoami/Library/Application Support/Google/Chrome/Default): [Enter]
Choose language [nimjs|nimwasm|python3]: python3[Enter]
第 132 场双周赛
Starts in: 0 days, 4 hours, 16 minutes, 12 seconds.
```

# Browser profile paths

If you have only one browser profile, just accept the default profile path. Otherwise, find the profile path for the current profile:

## Chrome

* Type `chrome://version` in the address bar.
* Copy the value of `Profile Path` (`个人资料路径`).

## Edge

* Type `edge://version` in the address bar.
* Copy the value of `Profile Path` (`个人资料路径`).

## Firefox

* Type `about://profiles` in the address bar.
* Copy the value of `Root Directory` of the desired profile.

# Commands

```bash
$ nlcc help
```

# Code templates

Code templates reside in respective folders in `tmpl`. Change the templates as needed (i.e. adding imports, code snippets, etc.), but leave the template variables intact.

# Editor

Visual Studio Code is hard-coded as the code editor and diff tool at the moment. May be configurable in the future.

# Local test (Experimental)

* Install Docker.
* Build docker image:

```bash
$ cd docker/python3
$ build.bat # windows
$ build.sh # others
```

* Use `nlcc test -l` instead of `nlcc test` to test locally

# Local debug (Experimental)

* Install Docker.
* Build docker image:

```bash
$ cd docker/python3
$ build.bat # windows
$ build.sh # others
```

* In your Python code, add `breakpoint()` to set breakpoints.
* Run `nlcc debug`.
* In VS Code, select the `Run and Debug`(运行和调试) tab, and launch `nlcc debug`. The debugger should stop at the first breakpoint.

# Develop

## New language support

Add new implementations of [BaseProject](src/projects/baseProject.nim) to [src/projects/](src/projects/). For example [Python3Project](src/projects/python/python3Project.nim). Pull requests are welcome.

## Cross-compilation for windows

* Install zig

```bash
$ brew install zig # OSX
```

* Build

```bash
$ ./build.sh
```

# TODO
* Browsers and OSes

| | Firefox | Chrome | Edge |
| --- | --- | --- | --- |
| Mac OS | ✅ | ✅ | ❌ |
| Windows | | ✅ | ✅ |
| Linux | | | ❌ |
* more langauges
  * [x] python
  * [ ] javascript
  * [ ] typescript
  * [ ] java
  * [ ] kotlin
  * [ ] cpp
  * [ ] go
  * [ ] rust
* [x] extract sample outputs from problem description
* [ ] generate test cases according to problem description
* docker env
  * [x] python
  * [x] javascript
  * [ ] limit memory and runtime
  * [ ] publish to hub
* [ ] support for global site
* [ ] support for multiple browser profiles
* [ ] protect extracted session
* [ ] realtime contest ratings
* [ ] compatibility with old folder structure
  * [x] compatibility with old code template
* github actions
  * [x] build
  * [ ] release
* [ ] split test cases
* custom data structures
  * [ ] list (https://leetcode.cn/problems/remove-duplicate-node-lcci/)
  * [x] tree (1586)
  * [ ] n-ary tree
  * [ ] graph
  * [x] design
  * [ ] call function
  * [ ] call method
  * [ ] modify args in-place (280.)
  * [ ] nested integer (339)
  * [x] employee (690)
  * [ ] doubly linked list (3263)

# Implementation details

* leetcode library: [nimleetcode](https://github.com/qszhu/nimleetcode/)
  * read leetcode session from browser: [nimbrowsercookies](https://github.com/qszhu/nimbrowsercookies)
    * chrome: [chrome.nim](https://github.com/qszhu/nimbrowsercookies/blob/main/src/nimbrowsercookies/chrome.nim)
      * macos
        * get key from keyring: [macos.nim](https://github.com/qszhu/nimbrowsercookies/blob/main/src/nimbrowsercookies/macos.nim)
        * derive key with pbkdf2: [pbkdf.nim](https://github.com/qszhu/nimtestcrypto/blob/main/src/nimtestcrypto/pbkdf.nim)
        * decrypt value with aes-128-cbc: [aes.nim](https://github.com/qszhu/nimtestcrypto/blob/main/src/nimtestcrypto/aes.nim)
      * windows
        * decrypt key with dpapi: [dpapi.nim](https://github.com/qszhu/nimbrowsercookies/blob/main/src/nimbrowsercookies/dpapi.nim)
        * decrypt value with aes-256-gcm: [aes.nim](https://github.com/qszhu/nimtestcrypto/blob/main/src/nimtestcrypto/aes.nim)
    * crypto: [nimtestcrypto](https://github.com/qszhu/nimtestcrypto)
  * parse javascript page data in html: [pageData.nim](https://github.com/qszhu/nimleetcode/blob/main/src/nimleetcode/pageData.nim)
    * parser combinator: [nimparsec](https://github.com/qszhu/nimparsec)
  * extract question sample output: [extraction.nim](https://github.com/qszhu/nimleetcode/blob/main/src/nimleetcode/extraction.nim)
* pull precompiled files: [pullPrecompiled.nim](src/scripts/pullPrecompiled.nim)
* compile nim to javascript: [nimJsProject.nim](src/projects/nimjs/nimJsProject.nim)
* compile nim to wasm: [nimWasmProject.nim](src/projects/nimwasm/nimWasmProject.nim)
  * build command: [build.tmpl](tmpl/nimwasm/build.tmpl)
  * handle IO: [post.tmpl](tmpl/nimwasm/post.tmpl)
