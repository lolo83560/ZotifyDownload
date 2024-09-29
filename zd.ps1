# Zotify Downloader wrapper - OPUS FORMAT
# parameter = Spotify URL 

param (
	[string]$url
)

# if no parameters give, display usage info
if ($psboundparameters.count -eq 0)
{
		"Usage: ZD `<spotify URL`>"
		exit
}

# retrieve page title from Spotify URL webpage
$page = Invoke-webrequest -Uri $url
$page.content -match "<title>(.+)</title>" | out-null	# get the <title> section
$title = $matches[1]
$title -match "(.*) \| Spotify" | out-null				# remove the ' | Spotify' right part
$temppath = $matches[1]

# replace problem chars for filenames [ < > : " / \ | ? * ] with a dash 
$localpath = $temppath -replace '[\<\>\:\"\/\\\|\?\*]','-'

# write-host [$url] [$localPath]

# from the URL, get the download type (track/album/playlist/episode/artist) & Spotify ID, transform into URI
$url -match "^.*/(.*?)/(.*?)$" | out-null	
$DLDtype = $matches[1]
$spotID = $matches[2]
$spoturi = "spotify:" + $DLDtype + ":" + $spotID

# write-host [$DLDtype] [$spotID] [$spoturi]

$rootpath = ".\\" # + $localpath

$output = switch ($DLDtype) {
   "playlist" { "{playlist}/{playlist_num} - {artist} - {song_name}.opus" ; break}
   "artist"   { "{artist}/{album}/{track_number} - {song_name}.opus" ; break}
   "album"    { "{artist}/{album}/{track_number} - {song_name}.opus" ; break}
   "track"    { "{artist}/{album} - {track_number} - {song_name}.opus" ; break}
   "episode"  { "{artist}/{song_name}.opus"; break}
   default    { "{artist}/{song_name}.opus"; break}
}


# to regenerate C:\Users\Laurent\AppData\Roaming\Zotify\credentials.json
# use librespot-auth while turning firewall off

# make unique name for logfile, generated from $localpath hash 
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$hash = [System.BitConverter]::ToString($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($localpath))).Replace("-", "").ToLower()
$logfilename = 'log-'+$hash+'.txt'

# now go ahead lopp it till completion
$iteration = 1
$startime = get-date
do {
	$("=" * 80)
	$("-" * $localpath.length)
	$localpath
	$("-" * $localpath.length)
	">>>> ITERATION $iteration <<<<"
	$("=" * 80)
	zotify --root-path $rootpath --output $output --retry-attempts 5 --print-download-progress=false --download-lyrics=false --download-format opus --download-quality high $spoturi 2>&1 | Tee-Object -file $logfilename
	$logerr = get-content $logfilename
	$iteration++
	"ErrGal " + ($logerr -match 'GENERAL DOWNLOAD ERROR').count
	"ErrKey " + ($logerr -match 'Audio key error').count
	"ErrCod " + ($logerr -match 'Traceback \(most recent call last\)').count
}
while ( 
		(($logerr -match 'GENERAL DOWNLOAD ERROR').count -ne 0) -or 
		(($logerr -match 'Audio key error').count -ne 0) -or
		(($logerr -match 'Traceback \(most recent call last\)').count -ne 0)
	)
$stoptime = get-date
remove-item -force $logfilename
"                                          "
"██████   ██████  ███    ██ ███████     ██ "
"██   ██ ██    ██ ████   ██ ██          ██ "
"██   ██ ██    ██ ██ ██  ██ █████       ██ "
"██   ██ ██    ██ ██  ██ ██ ██             "
"██████   ██████  ██   ████ ███████     ██ "
"                                          "
$deltime = ( "{0:hh\:mm\:ss}" -f [timespan]::fromseconds(($stoptime-$startime).totalseconds) )
'Time taken H:M:S: '+$deltime