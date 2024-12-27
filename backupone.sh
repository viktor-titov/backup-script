#!/bin/bash

# Путь к JSON-файлу
setting=".settingScript.json"

## $timeStamp - Timestamp format.
timeStamp="[%Y.%m.%d-%T]"

##  $txtFormat - Allow text formating (bold and colored text).
txtFormat=true

errorLog="backup-script.error.log"
logFile="backup-script.log"



msg() { 
    printf "%s \n" "$(date +"${timeStamp}"): $1";
}

## Text formating.
tf() {
  if [[ $txtFormat == true ]] ; then
    res=""
    for ((i=2; i<=$#; i++)) ; do
      case "${!i}" in
        "bold" ) res="$res\e[1m" ;;
        "underline" ) res="$res\e[4m" ;;
        "reverse" ) res="$res\e[7m" ;;
        "red" ) res="$res\e[91m" ;;
        "green" ) res="$res\e[92m" ;;
        "yellow" ) res="$res\e[93m" ;;
      esac
    done
    echo -e "$res$1\e[0m"
  else
    echo "$1"
  fi
}

check() {
    # Проверка, существует ли папка backups
    
    if [ ! -d "$1" ]; then
    msg "$(tf "Папка $1 не существует. Создайте папку и попробуйте снова." "red")"
    exit 1
    fi
}

logError() {
    while read -r line; do
        msg "$line">>"$errorLog"
    done
}

log() {
    while read -r line; do
        msg "$line">>"$logFile"
    done
}

exec 2> >(logError)

# Проверка существования файла
if [[ ! -f "$setting" ]]; then
    msg "$(tf "Файл с настройками $setting не существует. Создайте файл .settingScript.json рядом со скриптом и попробуйте снова." "red")"
    exit 1
fi


output=$(jq -r '.output' "$setting")
if [[ $? -ne 0 ]]; then
    msg "$(tf "Ошибка чтения файла $setting. Подробней в $errorLog" "red")"
    exit 1
fi

if [[ -z $output || $output = "null" ]]; then
    msg "$(tf "В файле $setting нет поля 'output', указывающее куда складывать файлы с архивами." "red")"
    exit 1
else 
    msg "$(tf "Вывод архивов по пути: $output" "yellow")"
fi

if [[ ! -r $output ]]; then
    mkdir $output
    msg "$(tf "Создана папка $output")"
fi

path=$1

if [[ -z $path || $path = "null" ]]; then 
    msg "$(tf "Укажите путь до файла или паки для архивирования." "red")"
    exit 1
fi


archive() {
    path="$output/$(date +"%Y.%m.%d")-$2-backup.tar.gz"
    if [ -e "$path" ]; then
        msg "$(tf "Backup для $1 уже создан." "yellow")"
        return 0
    fi

    tar czvf $path $1 > >(log)
    if [[ $? -ne 0 ]]; then
        msg "$(tf "Ошибка архивирования $1. Подробней в $errorLog" "red")"
        return 0
    fi

    msg "$(tf "done: $1" "green")"
    return 0
}


archive $path "$(basename $path)"

msg "$(tf "Подробно об операциях в файле $(pwd)/$logFile")"
