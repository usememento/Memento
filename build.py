import subprocess
import os
import shutil

if os.path.exists("build"):
    shutil.rmtree("build")
os.mkdir("build")

subprocess.run(["go", "build", "-o", "build/", "main.go"], shell=True)

shutil.copytree("./assets", "./build/assets")

os.chdir("./frontend")
subprocess.run(["flutter", "build", "web", "--web-renderer", "html", "--release"], shell=True)
os.chdir("..")
shutil.copytree("./frontend/build/web", "./build/frontend/build/web")
