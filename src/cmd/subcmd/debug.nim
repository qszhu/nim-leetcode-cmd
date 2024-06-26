import ../../projects/projects



proc debugCmd*(proj: BaseProject, port: int): bool =
  proj.debug(port)
  true
