
#   ---> s4 <---

# WARNING: must always be called twice on the same file:
# $ gawk -f select_all.awk file file

#2013-08.geoNoOrigFFS <- 'wtf1'| 'wtf2'| 'wtf3'|  'latitude' 'longitude' | 'username' | 'userid' | 'datetime' | 'msg'

## trim an string
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s) { return ltrim(rtrim(s)) }

## date to timestamp
# Translate a date in the received format to seconds since epoch
function get_seconds(horrible_date) {
	cmd = "date -d \"" horrible_date "\" +%s"
	cmd | getline secs
	close(cmd)     # isn't this horribly slow?
	return secs
}

## date to timestamp 2
# translates to seconds since 2013-01-01
# the previous attempt may be slow. or not. i don't really know.
function get_seconds2(horrible_date) {

	mes31 = 2678400;  # 31*24*60*60
	mes30 = 2592000;  # 30*24*60*60
	mesfb = 2419200;  # 28*24*60*60
	anho  = 31536000; # 365*24*60*60
	dia   = 3600;     # 60*60

    split(horrible_date, splat_date, " "); #  1   2   3     4       5    6
    split(splat_date[4], splat_hour, ":"); #             1  2  3
                                           # Thu Aug 01 00:01:41 +0000 2013
    ts = 0;

    ts = ts + (splat_date[3]-1) * 60 * 60 * 24; # date
    ts = ts +  splat_hour[1]    * 60 * 60     ; # hour
    ts = ts +  splat_hour[2]    * 60          ; # minutes
    ts = ts +  splat_hour[3]                  ; # seconds

    return ts
}

## Split words
# get only the words starting with c
function sw(msg, c) 
{
	x=""
	for (i in msg)
		if (substr(msg[i],1,1) == c && length(msg) > 1) {
			word=substr(msg[i],2)
			gsub(/[#@,.;!?¡¿:\-\(\)\[\]\"\'\|]/,"",word);
			if (length(word)>0) {
				x=x","word
			}
		}

	return substr(x,2)
}

## get mentioned ids
# translates the list of mentions to list of their ids
function gmi(msg) 
{
	x=""
	for (i in msg)
		if (substr(msg[i],1,1) == "@") {
			name=substr(msg[i],2)
			if (name in user_ids){
                #print name" is "user_ids[name]" or "my_ids[user_ids[name]]
				x=x","my_ids[user_ids[name]]
            }
		}

	return substr(x,2)
}

BEGIN { 
		FS    = "|"; 
		OFS   = "|";
        next_id = 1; # asignación de ids desde 1 hasta n, consecutivos, porque R

} 

# first pass
FNR == NR { 
	if (FNR!=1) { # skip the first line

		# trim fields (that need it)
		for (i = 5; i<= 6; i++) {
			gsub(/^ /, "", $i);
			gsub(/ $/, "", $i);
		}

        tid = trim($6)
		user_ids[$5] = tid;

        # asignar my_id si no lo tiene
        if (tid in my_ids) {
            #~ print tid" is already "my_ids[tid];
        } else {
            #~ print tid" will be "next_id;
            my_ids[tid] = next_id;
            next_id = next_id + 1;
        }
	} else {
        next_id=1;
    }
}

# second pass
FNR != NR {

	if (FNR!=1) { # skip the first line

		split($4,loc," "); 

		gsub(/[,.;!?¡¿:\-\(\)\[\]\"\'\|]/," ",$8); 
		num_mentions = split($8,msg," ");

        tid = trim($6)

        #~ print tid" es "my_id[tid];

		#                       2:latitude          4:userid        6:hashtags   7:mentions (id)         9: my "fake" id
		#     1:timestamp       |       3:longitude |    5:username |            |         8: mentions   |            10: whole message
		print get_seconds2($7), loc[1], loc[2],     tid, trim($5),  sw(msg,"#"), gmi(msg), sw(msg, "@"), my_ids[tid], $8; 
	}
	
}
