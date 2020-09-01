# -*- coding: utf-8 -*-
#!/usr/bin/python

import sys
import os
import re
import subprocess
import shutil
import uuid
import time
import xml.etree.cElementTree as ET
import config

def cleanBuild(apktool_d_dir, backupDir):
    # 删除 sign.apk、unsigned-align.apk、unsigned.apk、apktool_d_dir
    if os.path.exists('sign.apk'):
        os.remove('sign.apk')
    if os.path.exists('unsigned-align.apk'):
        os.remove('unsigned-align.apk')
    if os.path.exists('unsigned.apk'):
        os.remove('unsigned.apk')
    if os.path.exists(apktool_d_dir):
        shutil.rmtree(apktool_d_dir)
    if os.path.exists(backupDir):
        shutil.rmtree(backupDir)
    pass

def main():
    start = time.time()

    # 获取脚本当前文件夹路径
    curPath = sys.argv[1] + '/'
  
    # 提取母包文件名 
    defaultApk = ""
    fileNameList = os.listdir(curPath)
    for fileName in fileNameList:
        if fileName.rfind(".apk") != -1:
            defaultApk = fileName.replace('.apk','')
            break

    # 输出目录 
    outDir = curPath + "outApks"
    if os.path.exists(outDir):
        shutil.rmtree(outDir)
    os.makedirs(outDir)

    # 备份目录
    backupDir = curPath + 'srcBackup'
    if os.path.exists(backupDir):
        shutil.rmtree(backupDir)
    os.makedirs(backupDir)
    
    # 子包配置目录
    apkConfigsDir = curPath + 'apkConfigs'
    
    # 删除母包解包目录
    defaultApkDir = curPath + defaultApk
    if os.path.exists(defaultApkDir):
        shutil.rmtree(defaultApkDir)
        
    # 首先使用apktool拆开母包
    if subprocess.call('./apktool d ' + defaultApk + '.apk', shell=True) != 0:
        print('apktool 拆母包出错')
        return

    # 备份母包部分资源
    _src = os.path.join(defaultApk, 'assets')
    _dst = os.path.join(backupDir, 'assets')
    shutil.copytree(_src,_dst)

    successCnt = 0
    # 遍历文件夹
    for index in config.autoPackageIndex:
        # index就是目录名 可能目录不存在
        replaceDir = os.path.join(apkConfigsDir, str(index))
        if os.path.exists(replaceDir):
           
            # 替换 AndroidManifest.xml
            _src = os.path.join(replaceDir, 'AndroidManifest.xml')
            _dst = os.path.join(defaultApk, 'AndroidManifest.xml')
            shutil.copy2(_src, _dst)

            _src = os.path.join(replaceDir, 'values/strings.xml')
            _dst = os.path.join(defaultApk, 'res/values/strings.xml')

            # 替换 appname string.xml文件是合并过的 不能直接替换
            src_tree = ET.ElementTree(file=_src)
            dst_tree = ET.ElementTree(file=_dst)
            src_name = ''
            for src_child in src_tree.iterfind('string'):
                if src_child.attrib['name'] == 'app_name':
                    # 仅更换 app_name
                    src_name = src_child.text
                    break

            for dst_child in dst_tree.iterfind('string'):
                if dst_child.attrib['name'] == 'app_name':
                    dst_child.text = src_name
                    dst_tree.write(_dst, encoding="utf-8", xml_declaration=True)
                    break

            # 替换 icon
            _src = os.path.join(replaceDir, 'drawable-hdpi/icon.png')
            _dst = os.path.join(defaultApk, 'res/drawable-hdpi-v4/icon.png')
            shutil.copy2(_src, _dst)
            _src = os.path.join(replaceDir, 'drawable-ldpi/icon.png')
            _dst = os.path.join(defaultApk, 'res/drawable-ldpi-v4/icon.png')
            shutil.copy2(_src, _dst)
            _src = os.path.join(replaceDir, 'drawable-mdpi/icon.png')
            _dst = os.path.join(defaultApk, 'res/drawable-mdpi-v4/icon.png')
            shutil.copy2(_src, _dst)
            _src = os.path.join(replaceDir, 'drawable-xhdpi/icon.png')
            _dst = os.path.join(defaultApk, 'res/drawable-xhdpi-v4/icon.png')
            shutil.copy2(_src, _dst)

            #替换assets目录
            _dst = os.path.join(defaultApk, 'assets')
            _src = os.path.join(replaceDir, 'assets')
            if not os.path.isdir(_src):
                _src = os.path.join(backupDir, 'assets')
            if os.path.exists(_dst):
                shutil.rmtree(_dst)
            shutil.copytree(_src,_dst)


            # 替换完成 使用apktool生成apk
            if subprocess.call('./apktool b ' + defaultApk + ' -o unsigned.apk', shell=True) != 0:
                print('apktool 生成子包出错')
                return

            # 接下来是安卓的签名部分

            # 首先进行4字节对齐
            if subprocess.call('./zipalign -f -v 4 ./unsigned.apk ./unsigned-align.apk', shell=True) != 0:
                print('apk 4字节对齐出错')
                return
            
            # 进行 v1、v2 签名

            newfile = os.path.join(outDir, config.packageInfo[index]['apk'])
            keystorePath = './apkConfigs/' + str(index) + '/' + config.packageInfo[index]['keystore']
            # signCmd = 'jarsigner -verbose -keystore huanqiu_hq16.keystore -storepass huanqiu123456 -signedjar ' + newfile + ' -digestalg SHA1 -sigalg MD5withRSA unsigned-align.apk hq2'
            signCmd = './apksigner sign --ks ' + keystorePath + ' --ks-pass pass:' + config.packageInfo[index]['pass'] + ' --ks-key-alias ' + config.packageInfo[index]['alias'] + ' --key-pass pass:' + config.packageInfo[index]['pass'] + ' --out ' + newfile + ' unsigned-align.apk'
            
            if subprocess.call(signCmd, shell=True) != 0:
                print('签名失败')
                print(signCmd) 
                return
            print('出包索引:' + index + ' 状态:成功!')
            successCnt = successCnt + 1

    cleanBuild(defaultApk, backupDir)
    print ('出包总数:' + str(successCnt))
    end = time.time()
    print('耗时：')
    print(end-start)
            

if __name__ == '__main__':
    main()
