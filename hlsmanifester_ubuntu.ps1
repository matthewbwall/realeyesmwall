
Param(
   [string]$inputMP4,
   [int]$segmentTime
)

$input_file = Get-ChildItem -Path $inputMP4

Write-Host "Input File is $input_file"

$base_name = $input_file.BaseName

Write-Host "base_name is $base_name"

$base_folder = $PSScriptRoot + "/$base_name"

Write-Host "base_folder is $base_folder"

# Make folder to hold assets in and make names for them

$asset1 =  ($base_name + "_6000k"); $asset2 =  ($base_name + "_4800k"); $asset3 =  ($base_name + "_3700k"); 
$asset4 =  ($base_name + "_2500k"); $asset5 =  ($base_name + "_1100k"); $asset6 =  ($base_name + "_64k_audioonly");

New-Item -ItemType Directory -Path $PSScriptRoot -Name $base_name -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $base_folder -Name $asset1 -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $base_folder -Name $asset2 -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $base_folder -Name $asset3 -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $base_folder -Name $asset4 -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $base_folder -Name $asset5 -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $base_folder -Name $asset6 -ErrorAction SilentlyContinue

# Folder structure is created to hold the renditions and to map with the manifest file.

# Capture ffprobe info about file into json format 

$video_data = Invoke-Expression "ffprobe $inputMP4 -print_format json -show_format -show_streams" | ConvertFrom-Json

$v_width = $video_data.streams[0].width
$v_height = $video_data.streams[0].height
$v_codec = $video_data.streams[0].codec_tag_string
$v_fps = $video_data.streams[0].r_frame_rate; $v_fps = $v_fps.split("/") | Select-Object -First 1
$a_codec = $video_data.streams[1].codec_tag_string
$v_bitrate = $video_data.format.bit_rate

# split_by_time flag works in conjunction with segmentTime by allowing the segmenter to create segments on any frame, as opposed to only on a key frame.
# round_durations rounds up to an integer what would otherwise be a float point value for the duration of the segment on the hls playlist.
# hls_list_size of 0 is to force all segments to remain on the stream level m3u8 manifest.
# max and min rates with the corresponding buff size will help pad empty space and vice versa to help create a more-accurate segment duration and ease stress on the segmenter.
# force two channel aac with a 44kHz sample rate to be the most friendly audio possible.
# using sigle-second keyframes when passing the stream to the segmenter to allow the segmenter to cut as accurate of a keyframe on the six second mark as possible.

$asset_1_cmd = "ffmpeg -i $inputMP4 -c:v libx264 -b:v 6000k -minrate 6000k -maxrate 6000k -bufsize 6000k -r 24 -g 24 -vf scale=1920:1080 -c:a aac -b:a 128k -ac 2 -ar 44100 -coder 1 -segmentTime $segmentTime -hls_list_size 0 -hls_flags split_by_time+round_durations -hls_playlist_type vod -hls_segment_filename $base_name/$asset1/$base_name_%03d.ts `"$base_name/$asset1/$base_name.m3u8`""
$asset_2_cmd = "ffmpeg -i $inputMP4 -c:v libx264 -b:v 4800k -minrate 4800k -maxrate 4800k -bufsize 4800k -r 24 -g 24 -vf scale=1600:900 -c:a aac -b:a 128k -ac 2 -ar 44100 -coder 1 -segmentTime $segmentTime -hls_list_size 0 -hls_flags split_by_time+round_durations -hls_playlist_type vod -hls_segment_filename $base_name/$asset2/$base_name_%03d.ts `"$base_name/$asset2/$base_name.m3u8`""
$asset_3_cmd = "ffmpeg -i $inputMP4 -c:v libx264 -b:v 3700k -minrate 3700k -maxrate 3700k -bufsize 3700k -r 24 -g 24 -vf scale=1280:720 -c:a aac -b:a 128k -ac 2 -ar 44100 -coder 1 -segmentTime $segmentTime -hls_list_size 0 -hls_flags split_by_time+round_durations -hls_playlist_type vod -hls_segment_filename $base_name/$asset3/$base_name_%03d.ts `"$base_name/$asset3/$base_name.m3u8`""
$asset_4_cmd = "ffmpeg -i $inputMP4 -c:v libx264 -b:v 2500k -minrate 2500k -maxrate 2500k -bufsize 2500k -r 24 -g 24 -vf scale=960:540 -c:a aac -b:a 128k -ac 2 -ar 44100 -coder 1 -segmentTime $segmentTime -hls_list_size 0 -hls_flags split_by_time+round_durations -hls_playlist_type vod -hls_segment_filename $base_name/$asset4/$base_name_%03d.ts `"$base_name/$asset4/$base_name.m3u8`""
$asset_5_cmd = "ffmpeg -i $inputMP4 -c:v libx264 -b:v 1100k -minrate 1100k -maxrate 1100k -bufsize 1100k -r 24 -g 24 -vf scale=640:360 -c:a aac -strict -2 -b:a 128k -ac 2 -ar 44100 -segmentTime $segmentTime -hls_list_size 0 -hls_flags +split_by_time -hls_flags +round_durations -y -hls_segment_filename $base_name/$asset5/$base_name_%03d.ts $base_name/$asset5/$base_name.m3u8"
$asset_6_cmd = "ffmpeg -i $inputMP4 -c:a aac -b:a 128k -ac 2 -ar 44100 -coder 1 -f hls -segmentTime 6 -hls_list_size 0 -hls_flags split_by_time+round_durations -hls_playlist_type vod -hls_segment_filename $base_name/$asset6/$base_name_%03d.ts `"$base_name/$asset6/$base_name.m3u8`""

# Invoke ffmpeg

Invoke-Expression $asset_1_cmd
Invoke-Expression $asset_2_cmd
Invoke-Expression $asset_3_cmd
Invoke-Expression $asset_4_cmd
Invoke-Expression $asset_5_cmd
Invoke-Expression $asset_6_cmd

# Now create the master manifest that links these bad boy renditions up

# Base M3U8

$asset_1_m3u8 = "`n#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=$v_bitrate,BANDWIDTH=$v_bitrate,CODECS=`"$v_codec,$a_codec`",RESOLUTION=1920x1080,FRAMERATE=$v_fps" + "`n$asset1/$base_name.m3u8"
$asset_2_m3u8 = "`n#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=$v_bitrate,BANDWIDTH=$v_bitrate,CODECS`"$v_codec,$a_codec`",RESOLUTION=1600x900,FRAMERATE=$v_fps" + "`n$asset2/$base_name.m3u8"
$asset_3_m3u8 = "`n#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=$v_bitrate,BANDWIDTH=$v_bitrate,CODECS=`"$v_codec,$a_codec`",RESOLUTION=1280x720,FRAMERATE=$v_fps" + "`n$asset3/$base_name.m3u8"
$asset_4_m3u8 = "`n#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=$v_bitrate,BANDWIDTH=$v_bitrate,CODECS=`"$v_codec,$a_codec`",RESOLUTION=960x540,FRAMERATE=$v_fps" + "`n$asset4/$base_name.m3u8"
$asset_5_m3u8 = "`n#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=$v_bitrate,BANDWIDTH=$v_bitrate,CODECS=`"$v_codec,$a_codec`",RESOLUTION=640x360,FRAMERATE=$v_fps" + "`n$asset5/$base_name.m3u8"
$asset_6_m3u8 = "`n#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=$v_bitrate,BANDWIDTH=$v_bitrate,CODECS=`"$v_codec,$a_codec`",RESOLUTION=1920x1080,FRAMERATE=$v_fps" + "`n$asset6/$base_name.m3u8"

# Base stem of the main manifest
$manifest = @'
#EXTM3U
#EXT-X-VERSION:3
'@

# Build the manifest
$manifest = $manifest + $asset_1_m3u8 + $asset_2_m3u8 + $asset_3_m3u8 + $asset_4_m3u8 + $asset_5_m3u8 + $asset_6_m3u8

# Set a path for the output of the manifest 
$manifest_name = $base_folder + "/$base_name.m3u8"

# Output the main manifest
$manifest | Out-File $manifest_name