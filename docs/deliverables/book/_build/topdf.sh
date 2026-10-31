#!/bin/zsh
# usage: topdf.sh in.pptx out.pdf — Microsoft PowerPoint 로 PDF 내보내기.
# 다른 세션도 PowerPoint 를 쓰므로 '활성 문서'가 아니라 파일 이름으로 문서를 지정한다.
# 입력 파일은 이름이 겹치지 않게 임시 복사본(시각 포함)을 넘길 것.
IN="$1"; OUT="$2"; NAME="${IN:t}"
osascript <<OSA
tell application "Microsoft PowerPoint"
  open POSIX file "$IN"
  set p to missing value
  repeat 40 times
    try
      set p to presentation "$NAME"
      exit repeat
    end try
    delay 0.5
  end repeat
  save p in (POSIX file "$OUT") as save as PDF
  close p saving no
end tell
OSA
