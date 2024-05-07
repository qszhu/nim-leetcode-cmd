import ../../nlccrcs
import ../../lib/leetcode/lcSession


proc sync*(browser, profilePath: string): bool =
  let session = readSession(browser, profilePath)
  nlccrc.setLeetCodeSession($session)
  true