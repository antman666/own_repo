import requests
import os

for name in [core,extra]:
    page = requests.get('https://mirrors.bfsu.edu.cn/archlinux/%d/os/x86_64/%d.db.tar.gz', name,name)

b = []
for i in os.scandir('.'):
    if not i.name.startswith('.') and i.is_dir():
        b.append(i)
ver=[]
rel=[]

# TODO: 将本地包名和源中版本号和过期状态添加到列表中：{"包名":[vel,rel]}  <15-06-23, AntMan666> #
for i in os.scandir():
    if i.count():
        ver.append()

