@ECHO OFF

del /q chrono_msu1.ips
del /q ChronoTrigger_MSU1.zip
rmdir /s /q ChronoTrigger_MSU1

mkdir ChronoTrigger_MSU1
ucon64 -q --snes --chk chrono_msu1.sfc
ucon64 -q --mki=chrono_original.smc chrono_msu1.sfc
copy chrono_msu1.ips ChronoTrigger_MSU1
copy README.txt ChronoTrigger_MSU1
copy chrono_msu1.msu ChronoTrigger_MSU1
copy chrono_msu1.xml ChronoTrigger_MSU1
copy manifest.bml ChronoTrigger_MSU1
copy create_pcm.bat ChronoTrigger_MSU1
copy wav2msu.exe ChronoTrigger_MSU1

"C:\Program Files\7-Zip\7z" a -r ChronoTrigger_MSU1.zip ChronoTrigger_MSU1