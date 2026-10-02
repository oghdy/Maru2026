#!/bin/zsh
R=/Users/hadohadopapi/Desktop/Maru-main/docs/deliverables/report
osascript -e 'tell application "Microsoft Word" to close every document saving no' >/dev/null 2>&1
rm -f "$R/MARU_최종보고서_2학기.pdf"
osascript /private/tmp/claude-501/-Users-hadohadopapi-Desktop-Maru-main/1bebce81-4778-4178-b309-9db595216f63/scratchpad/topdf.applescript "$R/MARU_최종보고서_2학기.docx" "$R/MARU_최종보고서_2학기.pdf"
ls -la "$R"
