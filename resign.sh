#!/bin/sh

<< COMMAND
此為不改 Bundle ID 的改簽腳本
使用方法：
1. cd 到此腳本路徑
2. 把需要改簽的 ipa 放在 Raw 資料夾
3. 執行 ./resign.sh
4. 改簽完的 ipa 會放在 Done 資料夾中
COMMAND

# 透過 security find-identity -p codesigning -v 取得開發者簽名證書
RESIGN_CER="iPhone Distribution: XXXXXX"

# 重簽用 Provision Profile，必須是由 RESIGN_CER 開發者產出的
RESIGN_PROVISION=/ProvisionProfile/*.mobileprovision

# 改簽後的 ipa 路徑
NEW_IPA=Done/`date +'%Y-%m-%d'`.ipa

# /Raw/ 是否有需要簽署的 ipa
HAS_RAW_IPA='[ -f Raw/*.ipa ]'

# 本機是否有 RESIGN_CER 此開發者證書
HAS_CERT='security find-identity -v -p codesigning | grep -q "$RESIGN_CER"'

# 檢查 (/Raw/ 是否有需要簽署的 ipa) && (本機是否有 RESIGN_CER 此開發者證書)
if eval $HAS_RAW_IPA && eval $HAS_CERT; then
	echo "======================== 移除上次的改簽完成的 ipa"
	ls Done/*.ipa
	rm -rf Done/*.ipa

	echo "======================== 查看本機開發者證書"
	security find-identity -p codesigning -v

	# 查看描述檔案
	echo "======================== 查看描述檔案"
	security cms -D -i $RESIGN_PROVISION
	
	echo "======================== 創建 embedded.plist"
	# 通過 embedded.mobileprovision 文件創建 embedded.plist 文件
	security cms -D -i $RESIGN_PROVISION > embedded.plist

	echo "======================== 創建 entitlements.plist"
	# 通過 embedded.plist 文件 創建 entitlements.plist 文件
	/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' embedded.plist > entitlements.plist

	# 解壓 ipa 文件
	echo "======================== 解壓縮 ipa"
	ls Raw/*.ipa
	unzip Raw/*.ipa

	# 刪除 ipa 的簽名文件
	rm -rf Payload/*.app/_CodeSignature

	# 刪除動態庫的簽名文件，每個 framework 都要刪
	rm -rf Payload/*.app/Frameworks/*.framework/_CodeSignature

	# 動態庫重新簽名
	echo "======================== Frameworks 重新簽名開始..."
	codesign -f -s "$RESIGN_CER" Payload/*.app/Frameworks/*.framework

	echo "======================== 替換 embedded.mobileprovision"
	# 替換 app 中的 embedded.mobileprovision文件
	cp $RESIGN_PROVISION Payload/*.app/embedded.mobileprovision

	# app 重簽名
	echo "======================== App 重新簽名開始..."
	codesign -f -s "$RESIGN_CER" --no-strict --entitlements=entitlements.plist Payload/*.app

	# 查看 app 簽名訊息
	echo "======================== 查看 app 簽名訊息"
	codesign -vv -d Payload/*.app

	echo "======================== 打包 ipa..."
	# 打包 ipa
	zip -qr "$NEW_IPA" Payload

	echo "======================== 刪除多餘檔案..."
	# 刪除檔案
	rm -rf embedded.plist
	rm -rf entitlements.plist
	rm -rf Payload
	echo "======================== 結束，改簽後ipa: $NEW_IPA"
else
	# 錯誤輸出
	if ! eval $HAS_RAW_IPA; then
		echo "ERROR: 請將 ipa 放在 /Raw/ 中"
		ls Raw
	fi
	if ! eval $HAS_CERT; then
		echo "ERROR: 確認本機是否有 $RESIGN_CER 開發憑證"
		security find-identity -p codesigning -v
	fi
fi

