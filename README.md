# iOS IPA改簽腳本


## 改簽腳本 - ResignScript

此腳本為 IPA 改簽腳本，並不更改 `Bundle ID`  

### 使用方法
1. cd 到此腳本路徑  
2. 把需要改簽的 ipa 放在 `/Raw/` 資料夾  
3. 確保本機端有需要改簽的開發者證書  
4. 執行 `./resign.sh`  
5. 若出現 `zsh: permission denied: ./resign.sh` ，須先執行 `chmod +x resign.sh`  
6. 改簽完的 ipa 會放在 `/Done/` 資料夾中  

```
cd /ResignScript

./resign.sh
```

### 改簽步驟說明

1. 透過 `embedded.mobileprovision` 文件創建 `embedded.plist` 文件  
```
security cms -D -i $RESIGN_PROVISION > embedded.plist
```

2. 透過 `embedded.plist` 文件 創建 `entitlements.plist` 文件  
```
/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' embedded.plist > entitlements.plist
```

3. 解壓 IPA  
```
unzip Raw/*.ipa
```

4. 刪除 IPA 和 Frameworks 的簽名文件，每個 framework 都要刪  
```
rm -rf Payload/*.app/_CodeSignature
rm -rf Payload/*.app/Frameworks/*.framework/_CodeSignature
```

5. framework 重新簽名  
```
codesign -f -s "$RESIGN_CER" Payload/*.app/Frameworks/*.framework
```

6. 替換 App 中的 `embedded.mobileprovision` 文件  
```
cp $RESIGN_PROVISION Payload/*.app/embedded.mobileprovision
```

7. 重新簽名 App  
```
codesign -f -s "$RESIGN_CER" --no-strict --entitlements=entitlements.plist Payload/*.app
```

8. 檢查察看 App 簽名訊息  
```
codesign -vv -d Payload/*.app
```

9. 打包 IPA   
```
zip -qr "$NEW_IPA" Payload
```

10. 刪除多餘檔案  
```
rm -rf embedded.plist
rm -rf entitlements.plist
rm -rf Payload
```

### 可參考資料
[iOS ipa 重签名，修改/不修改包名均可](https://blog.csdn.net/lxmy2012/article/details/99647563)  
[重签名](https://blog.csdn.net/denggun12345/article/details/106340125)

***