set scriptPath to POSIX path of (path to me) & "Contents/Resources/import.sh"
tell application "Terminal"
	activate
	do script "clear; bash " & quoted form of scriptPath & "; echo; echo 'You can close this window.'"
end tell
