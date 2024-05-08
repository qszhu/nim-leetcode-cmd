import ../../projects/projects



proc buildCmd*(proj: BaseProject): bool =
  proj.build
