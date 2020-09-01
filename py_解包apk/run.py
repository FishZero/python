# -*- coding: utf-8 -*-
#!/usr/bin/python

import os
import sys
import shutil
import subprocess

def main():
    # 获取脚本当前文件夹路径
    curPath = sys.argv[1] + '/'
    print(sys.argv)
    # 提取apk文件名 
    defaultApks = []
    fileNameList = os.listdir(curPath)
    for fileName in fileNameList:
        if fileName.rfind(".apk") != -1:
            defaultApks.append(fileName.replace('.apk',''))
    print(defaultApks)
    successCnt = 0
    for defaultApk in defaultApks:
        # 删除母包解包目录
        defaultApkDir = curPath + defaultApk
        if os.path.exists(defaultApkDir):
            shutil.rmtree(defaultApkDir)

        # 使用apktool拆开母包  
        cmd = './apktool d '  + defaultApk + '.apk'
        print('开始解包:' + cmd)
        if subprocess.call(cmd, shell=True) != 0:
            print('apktool 解包出错')
            return
        else:
            successCnt = successCnt + 1
            print('apktool 解包成功')
    
    print('apk总数:' + str(len(defaultApks)))
    print('解包成功数:' + str(successCnt))
   

if __name__ == '__main__':
    main()
