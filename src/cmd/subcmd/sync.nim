import pkg/nimleetcode

import ../../nlccrcs



proc syncCmd*(browser: Browser, profilePath: string): bool =
  let session = readSession(browser, profilePath)
  nlccrc.setLeetCodeSession($session)
  true