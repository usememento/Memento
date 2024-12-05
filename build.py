import subprocess
import os
import shutil

if os.path.exists("build"):
    shutil.rmtree("build")
os.mkdir("build")

subprocess.run(["go", "build", "-o", "build/", "main.go"])

shutil.copytree("./assets", "./build/assets")

os.chdir("./web")
subprocess.run(["npm", "install"], shell=True)
subprocess.run(["npm", "run", "build"], shell=True)
os.chdir("..")
shutil.copytree("./web/dist", "./build/frontend/build/web")
