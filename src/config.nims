# switch("listCmd")
switch("define", "ssl")

when defined macosx:
    # if not Apple Silicon, remove following:
    amd64.windows.gcc.path = "/opt/homebrew/bin"
    i386.windows.gcc.path = "/opt/homebrew/bin"
