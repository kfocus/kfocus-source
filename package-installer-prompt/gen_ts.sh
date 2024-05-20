#!/bin/bash
langList=("es" "hi" "fr" "ar" "arn" "ast" "bg" "ca" "cs" "cy" "da" "de" "el" "en_GB" "eo" "es_VE" "et" "eu" "fa" "fi" "gl" "he" "hr" "hu" "id" "id_ID" "it" "ja" "kk" "ko" "lt" "lv" "nb_NO" "nl" "oc" "pl" "pt" "pt_BR" "ro_RO" "ru" "si" "sk_SK" "sl" "sr" "th" "tr" "uk" "vi" "zh_CN" "zh_TW")
for i in ${langList[@]}; do
    targetFile="src/translations/kubuntu-installer-prompt_$i.ts"
    if [ ! -e $targetFile ]; then
        echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > $targetFile
	echo "<!DOCTYPE TS>" >> $targetFile
        echo "<TS version=\"2.1\" language=\"$i\"></TS>" >> $targetFile
    fi
done
lupdate -no-obsolete src/*.cpp src/*.h src/*.ui -ts src/translations/*
