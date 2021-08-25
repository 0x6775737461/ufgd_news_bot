#!/bin/bash

declare -a data_arr
#the array begins in 1, not 0
#1: ufgd_news_url; #2: tg_bot_api; 3: bot_token; 4: chat_id; 5: dev_chat_id
for i in {1..5}
do
	data_arr[${i}]=$(sed -n "${i}p" ${1})
done

# make requests to ufgd news and parse this data
# maintin two files to compare in each requests
get_json() {
	news_json='/tmp/ufgd_news.json'

	if [[ -e /tmp/ufgd_news.json ]]; then
		cp  /tmp/ufgd_news.json /tmp/ufgd_news_old.json

		req=$(curl -s "${data_arr[1]}" -o /tmp/ufgd_news.json)
		if [[ ${req} -ne 0 ]]; then
			curl -s "${data_arr[2]}/bot${data_arr[3]}/sendMessage?chat_id=${data_arr[5]}&text=bug_ufgd_news"
		fi

		new_file_hash=$(md5sum < /tmp/ufgd_news.json)
		old_file_hash=$(md5sum < /tmp/ufgd_news_old.json)

		hash=1
		if [[ ${new_file_hash::32} != ${old_file_hash::32} ]]; then
			hash=0
		fi
	else
		curl -s "${data_arr[1]}" -o /tmp/ufgd_news.json
		hash=0
	fi
}

news() {
	if get_json; then
		news_title=$(jq '.Informes[0].titulo' ${news_json} | \
								 sed 's/\"//g; s/ /\+/g')

		news_desc=$(jq '.Informes[0].descricao' ${news_json} | \
								sed 's/\"//g; s/ /\+/g')

		news_resp_sec=$(jq '.Informes[0].setorResponsavel' ${news_json} | \
										sed 's/\"//g; s/ /\+/g')
										
		news_url=$(jq '.Informes[0].url' ${news_json} | \
							 sed 's/\"//g; s/ /\+/g')

		news_changes_date=$(jq '.Informes[0].alteracao' ${news_json} | \
												sed 's/\"//g; s/ /\+/g')

		title="*${news_title}*+%5F"
		changes_date="${news_changes_date}%5F%0A"
		resp_sec="%5FFonte:+${news_resp_sec}%5F%0A%0A"
		desc="${news_desc}%0A"
		url="(\[link\](https://ufgd.edu.br${news_url}))"

		full_text_news="${title}${changes_date}${resp_sec}${desc}${url}"

		if [[ ${hash} -eq 0 ]]; then
			bot_tg
		fi
	fi
}

bot_tg() {
	tg_api_url=${data_arr[2]}
	bot_data="bot${data_arr[3]}"
	method="sendMessage?chat_id=${data_arr[4]}"
	text="&text=${full_text_news}&parse_mode=markdown"

	post_req=$(curl -s "${tg_api_url}/${bot_data}/${method}${text}")
}

main() {
	while true; do
		news
		sleep 10
	done
}

main $@