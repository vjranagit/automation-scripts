#!/data/data/com.termux/files/usr/bin/bash
echo -ne "\n Checking if Termux has storage permission..."
rm -r ~/storage >/dev/null 2>&1
if ! touch /storage/emulated/0/.tmp_check_termux >/dev/null 2>&1
then
    echo -e "\nGrant Termux storage permission and run the script again\n"
    termux-setup-storage
    exit 1
fi
rm -rf /storage/emulated/0/.tmp_check_termux >/dev/null 2>&1
termux-setup-storage
echo "done"
apt update
pkg install -y git golang ffmpeg 2>/dev/null | grep -E '(Need to get |Get:|Unpacking |Setting up )'
tmpdir="$(mktemp -d)"
cd $tmpdir

git clone https://github.com/tulir/whatsmeow
i="$(grep -m 1 -n 'c := make(chan os.Signal)' whatsmeow/mdtest/main.go | grep -Eo '^[0-9]+')"
stop_line="$(wc -l whatsmeow/mdtest/main.go | grep -Eo '^[0-9]+')"
while (( $i < $stop_line ))
do
    ((i++))
    if sed -n "${i}p" whatsmeow/mdtest/main.go | grep -q "}()"
    then
        sed -i "${i} a args := os.Args[1:]\nif len(args) > 0 && args[0] != \"null\" {\n	if args[0] == \"both\" {\n		is_mode = \"both\"\n	} else if args[0] == \"receive\" {\n		is_mode = \"receive\" \n	} else if args[0] == \"send\" {\n		is_mode = \"send\"\n	} else {\n		handleCmd(strings.ToLower(args[0]), args[1:])\n	return\n	}\n}" whatsmeow/mdtest/main.go
        
break
    fi
done

del_start="$(grep -m 1 -n 'case "sendimg":' whatsmeow/mdtest/main.go | grep -Eo '^[0-9]+')"
del_stop="$(grep -m 1 -n 'case "setstatus":' whatsmeow/mdtest/main.go | grep -Eo '^[0-9]+')"
((del_stop--))
sed -i "$del_start,${del_stop}d" whatsmeow/mdtest/main.go
curl -s -O "https://gist.githubusercontent.com/HunterXProgrammer/fe60f4005af16caa6c407af66123558c/raw/3d0807d70677746945d8535d792f5c34cd093e91/extension_media_whatsmeow2_main.go"
sed -i -e '/case "setstatus":/{r extension_media_whatsmeow2_main.go' -e 'd}' whatsmeow/mdtest/main.go
rm extension_media_whatsmeow2_main.go

sed -i '0,/"mime"/s//"os\/exec"\n\t"io"\n\t"encoding\/base64"\n\t"io\/ioutil"/' whatsmeow/mdtest/main.go
sed -i "$(($(grep -nm 1 'case "getuser":' whatsmeow/mdtest/main.go | sed 's/:.*//')-1)) a case \"listusers\":\n		users, err := cli.Store.Contacts.GetAllContacts()\n		if err != nil {\n			log.Errorf(\"Failed to get user list: %v\", err)\n		} else {\n			for number, user := range users {\n				log.Infof(\"%v:%+v\", number, user)\n			}\n		}" whatsmeow/mdtest/main.go
sed -i "$(grep -nm 1 'log.Infof("Received message ' whatsmeow/mdtest/main.go | sed 's/:.*//') a if is_mode == \"both\" || is_mode == \"receive\" {\n			message := fmt.Sprintf(\"%s\", evt.Message.GetConversation())\n			extended_message := fmt.Sprintf(\"%s\", evt.Message.GetExtendedTextMessage())\n			sender_pushname := fmt.Sprintf(\"%s\", evt.Info.PushName)\n			sender_jid := fmt.Sprintf(\"%s\", evt.Info.Sender)\n			receiver_jid := fmt.Sprintf(\"%s\", evt.Info.Chat)\n			json_message, _ := json.Marshal(message)\n			json_extended_message, _ := json.Marshal(extended_message)\n			json_sender_pushname, _ := json.Marshal(sender_pushname)\n			var is_from_myself string\n			if evt.Info.MessageSource.IsFromMe {\n				is_from_myself = \"1\"\n			} else {\n				is_from_myself = \"0\"\n			}\n			if evt.Message.GetConversation() != \"\" {\n				json_data := fmt.Sprintf(\`{\"type\":\"message\",\"sender_jid\":\"%s\", \"receiver_jid\":\"%s\", \"sender_pushname\":%s, \"is_from_myself\":\"%s\", \"message\":%s}\`, sender_jid, receiver_jid, json_sender_pushname, is_from_myself, json_message)\n				log.Infof(\"%s\", json_data)\n				args := os.Args[1:]\n				if len(args) > 1 {\n					if os.Args[2] == \"net.dinglisch.android.taskerm\" {\n						intentTaskerm := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.taskerm\", \"--es\", \"json_data\", json_data)\n						intentTaskerm.Output()\n					} else if os.Args[2] == \"net.dinglisch.android.tasker\" {\n						intentTasker := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.tasker\", \"--es\", \"json_data\", json_data)\n						intentTasker.Output()\n					} else {\n						intentTaskerm := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.taskerm\", \"--es\", \"json_data\", json_data)\n						intentTaskerm.Output()\n						intentTasker := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.tasker\", \"--es\", \"json_data\", json_data)\n						intentTasker.Output()\n					}\n				} else {\n					intentTaskerm := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.taskerm\", \"--es\", \"json_data\", json_data)\n					intentTaskerm.Output()\n					intentTasker := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.tasker\", \"--es\", \"json_data\", json_data)\n					intentTasker.Output()\n				}\n			} else if evt.Message.GetExtendedTextMessage() != nil {\n				json_data := fmt.Sprintf(\`{\"type\":\"extended_message\",\"sender_jid\":\"%s\", \"receiver_jid\":\"%s\", \"sender_pushname\":%s, \"is_from_myself\":\"%s\", \"message\":%s}\`, sender_jid, receiver_jid, json_sender_pushname, is_from_myself, json_extended_message)\n				log.Infof(\"%s\", json_data)\n				args := os.Args[1:]\n				if len(args) > 1 {\n					if os.Args[2] == \"net.dinglisch.android.taskerm\" {\n						intentTaskerm := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.taskerm\", \"--es\", \"json_data\", json_data)\n						intentTaskerm.Output()\n					} else if os.Args[2] == \"net.dinglisch.android.tasker\" {\n						intentTasker := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.tasker\", \"--es\", \"json_data\", json_data)\n						intentTasker.Output()\n					} else {\n						intentTaskerm := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.taskerm\", \"--es\", \"json_data\", json_data)\n						intentTaskerm.Output()\n						intentTasker := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.tasker\", \"--es\", \"json_data\", json_data)\n						intentTasker.Output()\n					}\n				} else {\n					intentTaskerm := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.taskerm\", \"--es\", \"json_data\", json_data)\n					intentTaskerm.Output()\n					intentTasker := exec.Command(\"am\", \"broadcast\", \"-a\", \"intent.from.mdtest\", \"-p\", \"net.dinglisch.android.tasker\", \"--es\", \"json_data\", json_data)\n					intentTasker.Output()\n				}\n			}\n		}" whatsmeow/mdtest/main.go


line="$(grep -n 'cli.Disconnect()' whatsmeow/mdtest/main.go | sed 's/:.*//' | sort -r)"

for i in $line
do
	sed -i "${i} a if is_mode == \"both\" || is_mode == \"receive\" || is_mode == \"send\" {\n	kill_server()\n}" whatsmeow/mdtest/main.go
done

