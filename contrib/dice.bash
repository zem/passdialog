# Copyright 2019 1553A52AE25725279D8A499175E880E6DC59190F
# 
# This file is licenced under the GPLv2+. Please see COPYING_dice.bash.txt for more information.
#
# As we plan to have a replacement for pass generate in pass dice 
# cmd_generate() {
	local opts no_caps="" delemiter="" wordlist="" specials="" qrcode=0 clip=0 force=0 inplace=0 pass
	opts="$($GETOPT -o nd:w:s:qcif -l no-caps,delemiter:,wordlist:,specials:,qrcode,clip,in-place,force -n "$PROGRAM" -- "$@")"
	local err=$?
	eval set -- "$opts"
	while true; do case $1 in
		-n|--no-caps) no_caps="--no-caps"; shift ;;
		-d|--delemiter) delemiter="$2"; shift ; shift ;;
		-w|--wordlist) wordlist="-w $2"; shift; shift ;;
		-s|--specials) specials="-s $2"; shift; shift ;;
		-q|--qrcode) qrcode=1; shift ;;
		-c|--clip) clip=1; shift ;;
		-f|--force) force=1; shift ;;
		-i|--in-place) inplace=1; shift ;;
		--) shift; break ;;
	esac done

	[[ $err -ne 0 || ( $# -ne 2 && $# -ne 1 ) || ( $force -eq 1 && $inplace -eq 1 ) || ( $qrcode -eq 1 && $clip -eq 1 ) ]] && die "Usage: $PROGRAM $COMMAND [--no_caps,-n] [--delemiter STR,-d STR] [--wordlist STR,-w STR] [--specials NUM,-s NUM] [--clip,-c] [--qrcode,-q] [--in-place,-i | --force,-f] pass-name [pass-length]"
	local path="$1"
	local length="${2:-$GENERATED_LENGTH}"
	check_sneaky_paths "$path"
	[[ $length =~ ^[0-9]+$ ]] || die "Error: pass-length \"$length\" must be a number."
	[[ $length -gt 0 ]] || die "Error: pass-length must be greater than zero."
	mkdir -p -v "$PREFIX/$(dirname -- "$path")"
	set_gpg_recipients "$(dirname -- "$path")"
	local passfile="$PREFIX/$path.gpg"
	set_git "$passfile"

	[[ $inplace -eq 0 && $force -eq 0 && -e $passfile ]] && yesno "An entry already exists for $path. Overwrite it?"

	pass=$(diceware $no_caps -d "${delemiter}" $wordlist $specials -n $length) || die "Could not generate password using the 'diceware $no_caps -d \"${delemiter}\" $wordlist $specials -n $length' cmd use '$PROGRAM $COMMAND -h' to get a usage info for pass."
	if [[ $inplace -eq 0 ]]; then
		echo "$pass" | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}" || die "Password encryption aborted."
	else
		local passfile_temp="${passfile}.tmp.${RANDOM}.${RANDOM}.${RANDOM}.${RANDOM}.--"
		if { echo "$pass"; $GPG -d "${GPG_OPTS[@]}" "$passfile" | tail -n +2; } | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile_temp" "${GPG_OPTS[@]}"; then
			mv "$passfile_temp" "$passfile"
		else
			rm -f "$passfile_temp"
			die "Could not reencrypt new password."
		fi
	fi
	local verb="Add"
	[[ $inplace -eq 1 ]] && verb="Replace"
	git_add_file "$passfile" "$verb generated password for ${path}."

	if [[ $clip -eq 1 ]]; then
		clip "$pass" "$path"
	elif [[ $qrcode -eq 1 ]]; then
		qrcode "$pass" "$path"
	else
		printf "\e[1mThe generated password for \e[4m%s\e[24m is:\e[0m\n\e[1m\e[93m%s\e[0m\n" "$path" "$pass"
	fi
# }


