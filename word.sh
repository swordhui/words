#!/bin/bash

#
# word -- dictionary of yourself
# 
# by Zhang Lihui <swordhuihui@gmail.com>, 2010-04-13, 15:58
#


WORDPATH=~
WORDFILE=$WORDPATH/words

#color defines
## Set color commands, used via $ECHO
# Please consult `man console_codes for more information
# under the "ECMA-48 Set Graphics Rendition" section
#
# Warning: when switching from a 8bit to a 9bit font,
# the linux console will reinterpret the bold (1;) to
# the top 256 glyphs of the 9bit font. This does
# not affect framebuffer consoles
NORMAL="\\033[0;39m" # Standard console grey
SUCCESS="\\033[1;32m" # Success is green
WARNING="\\033[1;33m" # Warnings are yellow
FAILURE="\\033[1;31m" # Failures are red
INFO="\\033[1;36m" # Information is light cyan
BRACKET="\\033[1;34m" # Brackets are blue



#
# version and  usage 
#
words_version=0.1.1
words_usage="
word.sh $SUCCESS$words_version$NORMAL, usage:\n
	$INFO\t-v               $NORMAL show current version\n
	$INFO\t-a               $NORMAL add a word\n
	$INFO\t-l               $NORMAL list all words\n
	$INFO\t-s               $NORMAL slide show mode\n
	$INFO\t-w               $NORMAL write mode\n
	$INFO\t-r rank          $NORMAL only rank x\n
"
words_show_usage()
{
	echo -e $words_usage
}

#check return code. show $1 if error.
err_check()
{
	if [ $? != 0 ]; then
		echo -e $FAILURE"$1"
		exit 1
	fi
}

words_add()
{
	local name
	local means
	local example

	if [ -f $WORDFILE ]; then
		echo "word    :"
	else
		mkdir -p $WORDPATH
		touch $WORDFILE
		err_check "Cannot create $WORDFILE."
		echo "word    :"
	fi

	read name
	echo "means   :"
	read means
	echo "example :"
	read example

	echo "$name:0:$means:$example:0:0" >> $WORDFILE

}

#split csv line. 
#input: $1="good,i love u,123"
#output: count=3, value[0]=good, value[1]="i love u", value[2]=123
csv_split()
{
	count=0
	local retv=$1
	unset value

	while [ -n "$retv" ]
	do
		value[$count]=${retv%%:*}
		#echo "value_$count=${value[$count]}"

		retv=${retv#${value[$count]}}
		retv=${retv#:}
		#echo "retv=$retv"

		count=$(($count+1))
	done
}

gpkg_csvop_ls()
{
	local name
	local rank
	local good
	local bad

	name=${value[0]}
	rank=${value[1]}
	good=${value[4]}
	bad=${value[5]}
	lscount=$(($lscount+1))
	printf "%-5d R%d %-20s (%d, %d)\n" $lscount $rank $name $good $bad
}

gpkg_csvop_sort()
{
	local score
	local index

	score=${value[0]}
	index=${value[1]}

	aindex[$sort_ind]=$index;
	sort_ind=$(($sort_ind+1))
}
	
gpkg_csvop_write()
{
	local name
	local rank
	local means
	local example
	local good
	local bad

	name=${value[0]}
	rank=${value[1]}
	means=${value[2]}
	example=${value[3]}
	good=${value[4]}
	bad=${value[5]}

	aname[$lscount]=$name;
	arank[$lscount]=$rank;
	ameans[$lscount]=$means;
	aexample[$lscount]=$example;
	agood[$lscount]=$good
	abad[$lscount]=$bad


	lscount=$(($lscount+1))
	#printf "%-5d R%d %s\n" $lscount $rank $name
}

gpkg_read()
{
	local line
	local count
	local -a value

	while IFS= read -r line
	do
		[ -z "$line" ] && continue

		csv_split "$line"
		case "$XG_CSV_OP" in
		l)
			gpkg_csvop_ls
			;;
		w)
			gpkg_csvop_write
			;;
		s)
			gpkg_csvop_sort
			;;

		*)
			gpkg_csvop_ls
			;;
		esac

	done
}
words_list()
{
	XG_CSV_OP="l"
	lscount="0"
	gpkg_read < $WORDFILE

	echo ""
	echo "Total : $lscount"
}

words_update()
{
	local ind;
	local name;
	local new

	ind=$1
	name=${aname[$ind]}
	good=${agood[$ind]}
	bad=${abad[$ind]}

	sed -i "/$name:.*/ s/:[0-9]*:[0-9]*$/:$good:$bad/" $WORDFILE 
}
	

words_show_write()
{
	local ind;
	local name;

	ind=$1
	
	echo ${ameans[$ind]}
	read name
	if [ "$name" == "${aname[$ind]}" ]; then
		echo "Right"
		agood[$ind]=$((${agood[$ind]} + 1))
	else
		echo "Wrong"
		abad[$ind]=$((${abad[$ind]} + 1))
	fi
	echo ${aexample[$ind]}
	echo 
	words_update $ind
}


words_sort()
{
	local score
	local ind

	rm /tmp/words_sort_aa 2>/dev/null
	touch /tmp/words_sort_aa
	err_check "Create /tmp/words_sort_aa failed."
	
	for((ind=0; ind<$lscount; ind++))
	do
		score=$(( ${agood[$ind]} - ${abad[$ind]} * 10 ))
		echo "$score:$ind" >> /tmp/words_sort_aa
	done

	cat /tmp/words_sort_aa | sort -n > /tmp/words_sort_bb
	err_check "Sort Failed."

	#read new array
	sort_ind=0
	XG_CSV_OP="s"
	unset aindex
	gpkg_read < /tmp/words_sort_bb
	
}

words_write()
{
	local ind=0;
	XG_CSV_OP="w"
	lscount="0"
	unset ameans
	unset aname
	unset arank
	unset aexample
	unset agood
	unset abad
	gpkg_read < $WORDFILE

	echo ""
	echo "Total : $lscount"

	words_sort;

	for((ind=0; ind<$lscount; ind++))
	do
		words_show_write ${aindex[$ind]}
	done
}

#rank=$(echo $1 | grep -o  -e "-r [0-5]")
#echo $rank 
	

case "${1}" in
-v)
	#show version.
	echo $words_version
	;;
-a)
	#add works
	words_add;
	;;
-l)
	#add works
	words_list;
	;;
-w)
	#add works
	words_write;
	;;

*)
	#show usage 
	words_show_usage
	exit 0
	;;
esac


