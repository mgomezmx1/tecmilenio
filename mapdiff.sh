#!/bin/bash

# declare associative array (hashmap)
declare -A firefox_procs

# main while loop
while true; do
	# print separator between runs
	printf "=%.0s" {1..60}
	printf "\n"

	# declare hashmap for this run
	unset new_firefox_procs
	declare -A new_firefox_procs

	# populate new hashmap with files mapped for each firefox process
	for it in $(pidof firefox); do
		printf "\n\033[33m\033[1m >>> PROC:firefox    PID:$it\033[0m\n"

		pmap_out=$( pmap -x $it                          `# pmap of current process`      \
				  | head -n -2                           `# ignore 2 footer lines`        \
				  | tail -n +3                           `# ignore 3 header lines`        \
				  | awk '{$1=$2=$3=$4=$5=""; print $0}'  `# get only maps`                \
				  | tr -d ' '                            `# delete spaces`                \
				  | sort                                 `# do not use any other locale!` \
				  | uniq -d                              `# eliminate duplicates`         \
				  )
		
		new_firefox_procs[$it]=$pmap_out

		# lines that appear in new pmap but not in old one
		new_maps=$(comm -23                            \
				   <(echo "${new_firefox_procs[$it]}") \
				   <(echo "${firefox_procs[$it]}")     \
				   2>/dev/null                         \
				  )

		# lines that appear in old pmap but not in new one
		old_maps=$(comm -23                            \
				   <(echo "${firefox_procs[$it]}")     \
				   <(echo "${new_firefox_procs[$it]}") \
				   2>/dev/null                         \
				  )

		# print diffs between maps in fancy manner
		printf "\033[32m"
		for map_it in $new_maps; do
			printf "\t+ $map_it\n"
		done

		printf "\033[31m"
		for map_it in $old_maps; do
			printf "\t- $map_it\n"
		done

		printf "\033[0m"		
	done

	# update firefox_procs with new_firefox_procs
	unset firefox_procs
	declare -A firefox_procs

	for it in "${!new_firefox_procs[@]}"; do
		firefox_procs[$it]="${new_firefox_procs[$it]}"
	done

	# wait for newline before next run
	read -e >/dev/null
done
