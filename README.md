# Getting started

* Login in your preferred browser (Chrome/Edge/Firefox).
* Close the browser and make sure no browser processes are running.
* In a new folder, run `nlcc`:

```bash
$ nlcc
Choose browser [firefox|chrome|edge] (chrome): [Enter]
Browser profile path (/Users/whoami/Library/Application Support/Google/Chrome/Default): [Enter]
Choose language [nimjs|python3]: python3[Enter]
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
$ nlcc start weekly-contest-400 # start a speicified contest, contest url is also accepted
$ nlcc test # build and test solution for current question
$ nlcc build # build solution for current question
$ nlcc submit # build and submit solution for the current question
              # if the solution is accepted, the next question would be opened
$ nlcc next # open next question to solve
$ nlcc select 3 # select the specified question in the contest to solve
$ nlcc startIdx 4 # set the first question to solve in the contest
$ nlcc lang # change language
$ nlcc sync # sync cookies from browser (e.g. if the cookies expired and you need to login again)
```

# Code templates

There would be a default `.tmpl` template file created in the current folder. Change the file as needed (i.e. adding imports, code snippets, etc.), but leave the template variables intact.

# Editor

Visual Studio Code is hard-coded as the code editor and diff tool at the moment. May be configurable in the future.

# Develop

## New language support

Add new implementations of [BaseProject](src/projects/baseProject.nim) to [src/projects/](src/projects/). For example [Python3Project](src/projects/python/python3Project.nim). Pull requests are welcome.
## [Cross-compilation for windows](https://nim-lang.github.io/Nim/nimc.html#crossminuscompilation-for-windows)

```bash
$ brew install mingw-w64 # OSX
```

* Modify `nim.cfg` as needed.

## Build

```bash
$ ./build.sh
```

# TODO
* Browsers and OSes

| | Firefox | Chrome | Edge |
| --- | --- | --- | --- |
| Mac OS | ✔ | ✔ | ❌ |
| Windows | | ✔ | ✔ |
| Linux | | | ❌ |
* more langauges
  * [x] python
  * [ ] javascript
  * [ ] typescript
  * [ ] java
  * [ ] cpp
* [ ] extract sample outputs from problem description
* [ ] generate test cases according to problem description
* [ ] test solutions locally
* [ ] support for global site
* [ ] support for multiple browser profiles
* [ ] display realtime contest ratings
* [ ] compatibility for old folder structure
  * [x] compatibility with old code template
* [ ] update self

# Implementation details

* leetcode library: [nimleetcode](https://github.com/qszhu/nimleetcode/)
  * read leetcode session from browser: [nimbrowsercookies](https://github.com/qszhu/nimbrowsercookies)
    * chrome: [chrome.nim](https://github.com/qszhu/nimbrowsercookies/blob/main/src/nimbrowsercookies/chrome.nim)
      * macos
        * get key from keyring
        * derive key with pbkdf2: [pbkdf.nim](https://github.com/qszhu/nimtestcrypto/blob/main/src/nimtestcrypto/pbkdf.nim)
        * decrypt value with aes-128-cbc: [aes.nim](https://github.com/qszhu/nimtestcrypto/blob/main/src/nimtestcrypto/aes.nim)
      * windows
        * decrypt key with dpapi: [dpapi.nim](https://github.com/qszhu/nimbrowsercookies/blob/main/src/nimbrowsercookies/dpapi.nim)
        * decrypt value with aes-256-gcm: [aes.nim](https://github.com/qszhu/nimtestcrypto/blob/main/src/nimtestcrypto/aes.nim)
    * crypto: [nimtestcrypto](https://github.com/qszhu/nimtestcrypto)
  * parse javascript page data in html: [pageData.nim](https://github.com/qszhu/nimleetcode/blob/main/src/nimleetcode/pageData.nim)
    * parser combinator: [nimparsec](https://github.com/qszhu/nimparsec)