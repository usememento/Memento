import subprocess
import os
import shutil

if os.path.exists("build"):
    shutil.rmtree("build")
os.mkdir("build")

subprocess.run(["go", "build", "-o", "build/", "main.go"])

shutil.copytree("./assets", "./build/assets")

os.chdir("./frontend")
if os.name == "nt":
    subprocess.run(["flutter.bat", "build", "web", "--web-renderer", "html", "--release"])
else:
    subprocess.run(["flutter", "build", "web", "--web-renderer", "html", "--release"])
os.chdir("..")
shutil.copytree("./frontend/build/web", "./build/frontend/build/web")
