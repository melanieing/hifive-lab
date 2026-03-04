# 1. 베이스 이미지 설정 (가벼운 웹서버인 nginx 사용)
FROM nginx:alpine

# 2. 내가 만든 HTML 파일을 컨테이너 안의 nginx 경로로 복사
COPY index.html /usr/share/nginx/html/index.html

# 3. 80번 포트 개방
EXPOSE 80

# 4. nginx 실행 (이미지에 기본 설정되어 있어 생략 가능하지만 명시적 표기)
CMD ["nginx", "-g", "daemon off;"]