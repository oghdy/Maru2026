# MARU 웹 체험판 정적 서버: / = 랜딩, /app/ = Flutter 앱.
# 빌드 컨텍스트는 이 폴더(deploy/web-demo). site/app/ 은 scripts/build_web_demo.sh 로 만들어 커밋한다.
FROM nginx:alpine

# Railway 는 실행 때 PORT 를 넣어 준다. 이 값은 로컬에서 docker run 할 때만 쓰인다.
ENV PORT=8080

# 공식 이미지의 시작 스크립트가 환경 변수를 채워 /etc/nginx/conf.d/default.conf 로 만든다.
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY site /usr/share/nginx/html
