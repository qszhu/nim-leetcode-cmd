import ../../nlccrcs
import ../../lib/leetcode/lcSession



proc syncCmd*(browser: Browser, profilePath: string): bool =
  let session = readSession(browser, profilePath)
  nlccrc.setLeetCodeSession($session)
  true