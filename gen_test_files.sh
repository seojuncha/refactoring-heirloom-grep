#!/usr/bin/env bash
set -euo pipefail

mkdir -p tests

# 1) small.txt: 기본 동작 확인 (라인 번호, 단순 매칭)
cat > tests/small.txt <<'EOF'
hello world
foo bar baz
Foo fighters
foobar
bar
# comment line
EOF

# 2) multi.txt: 여러 파일/여러 라인, -n/-v/-c 등 확인
cat > tests/multi.txt <<'EOF'
alpha beta gamma
foo is here
nothing to see
another Foo sample
foofoo (overlap case)
EOF

# 3) edge.txt: 공백/탭/빈 줄/선행·후행 공백, -x(전체 라인), 공백 처리 확인
cat > tests/edge.txt <<'EOF'

   leading spaces
trailing spaces   
tabs	and	more	tabs
only-space-line:        
exact-line
exact-line   
EOF

# 4) regex.txt: 메타문자/앵커/그룹/수량자/-E/-F/-w 확인
cat > tests/regex.txt <<'EOF'
^start
end$
a.c
a*c
(abc)
[abc]
foo123
foo_123
foo-123
foo.bar
2025-08-12
repeated foo foo foo
EOF

# 5) case.txt: 대소문자, -i 테스트
cat > tests/case.txt <<'EOF'
foo
Foo
FOO
fOo
bar
EOF

# 6) word.txt: 단어 경계 테스트(-w 참고; 구현 여부에 따라 다름)
cat > tests/word.txt <<'EOF'
foo
foo!
[foo]
foo_bar
bar-foo
football
EOF

# 7) unicode.txt: UTF-8 (한글/이모지/조합형), -i 동작 범위 참고
cat > tests/unicode.txt <<'EOF'
한글 테스트: 서울에 foo 가 있다
대소문자 테스트: Straße vs STRASSE
이모지: 🙂 foo 😎
조합형: café vs café
영문혼합: Foo와 bar가 섞임
EOF

# 8) longline.txt: 매우 긴 라인(> 10k), 버퍼 경계/스트리밍 확인
#    'foo'를 중간에 심어 탐색 가능하게 함
python3 - <<'PY'
s = "A"*5000 + "foo" + "B"*7000 + "\n"
with open("tests/longline.txt", "w", encoding="utf-8") as f:
    f.write(s)
PY

# 9) no_newline.txt: 마지막 줄 개행 없음 처리 확인
printf "last line without newline with foo" > tests/no_newline.txt

# 샘플 패턴 안내 파일(읽기 전용)
cat > tests/README_patterns.txt <<'EOF'
추천 테스트 패턴/옵션 (patterns & options)
-----------------------------------------
기본:
  ./grep foo tests/small.txt
라인 번호:
  ./grep -n foo tests/multi.txt
대소문자 무시(ASCII 기준):
  ./grep -i foo tests/case.txt
부정 매칭:
  ./grep -v foo tests/multi.txt
정규식 메타(-E 확장 정규식):
  ./grep -E 'foo[0-9]+' tests/regex.txt
  ./grep -E '^(start|end$)' tests/regex.txt
리터럴(-F 고정 문자열):
  ./grep -F '(abc)' tests/regex.txt
전체 라인 일치(-x):
  ./grep -x 'exact-line' tests/edge.txt
단어 경계(-w, 구현 시):
  ./grep -w foo tests/word.txt
유니코드 확인(참고: 구현/라이브러리 따라 상이):
  ./grep foo tests/unicode.txt
긴 라인 버퍼 경계:
  ./grep foo tests/longline.txt
마지막 개행 없음:
  ./grep foo tests/no_newline.txt
여러 파일:
  ./grep foo tests/small.txt tests/multi.txt tests/edge.txt
EOF

echo "Created test files under ./tests"