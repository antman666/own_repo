import requests
import os
import tarfile

for name in [core, extra]:
    page = requests.get(
        "https://mirrors.bfsu.edu.cn/archlinux/%s/os/x86_64/%s.db.tar.gz" % (name, name)
    )
    with open("/tmp/%s.db.tar.gz" % name, "wb") as f:
        f.write(page.content)
    tarfile.open("/tmp/%s.db.tar.gz" % name).extractall("/tmp/%s" % name)

b = []
for i in os.scandir("."):
    if not i.name.startswith(".") and i.is_dir():
        b.append(i)
ver = []
rel = []

# TODO: 将本地包名和源中版本号和过期状态添加到列表中：{"包名":[vel,rel]}  <15-06-23, AntMan666> #
for i in os.scandir():
    if i.count():
        ver.append()
