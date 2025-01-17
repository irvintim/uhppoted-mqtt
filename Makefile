DEBUG  ?= --debug
DIST   ?= development

SERIALNO  ?= 405419896
CARD      ?= 1327679
REQUESTID ?= AH173635G3
CLIENTID  ?= QWERTY54
REPLYTO   ?= uhppoted/reply/97531
DATETIME  = $(shell date "+%Y-%m-%d %H:%M:%S")

.PHONY: clean
.PHONY: update
.PHONY: update-release

all: test      \
	 benchmark \
     coverage

clean:
	go clean
	rm -rf bin

update:
	go get -u github.com/uhppoted/uhppote-core@master
	go get -u github.com/uhppoted/uhppoted-lib@master
	go get -u github.com/aws/aws-sdk-go
	go get -u github.com/eclipse/paho.mqtt.golang
	go get -u github.com/gorilla/websocket
	go get -u golang.org/x/net
	go get -u golang.org/x/sys
	go mod tidy

update-release:
	go get -u github.com/uhppoted/uhppote-core
	go get -u github.com/uhppoted/uhppoted-lib
	go get -u github.com/aws/aws-sdk-go
	go get -u github.com/eclipse/paho.mqtt.golang
	go get -u github.com/gorilla/websocket
	go get -u golang.org/x/net
	go get -u golang.org/x/sys
	go mod tidy

format: 
	go fmt ./...

build: format
	mkdir -p bin
	go build -trimpath -o bin ./...

test: build
	go test ./...

vet: build
	go vet ./...

lint: build
	golint ./...

benchmark: build
	go test -bench ./...

coverage: build
	go test -cover ./...

build-all: test vet
	mkdir -p dist/$(DIST)/windows
	mkdir -p dist/$(DIST)/darwin
	mkdir -p dist/$(DIST)/linux
	mkdir -p dist/$(DIST)/arm7
	env GOOS=linux   GOARCH=amd64         go build -trimpath -o dist/$(DIST)/linux   ./...
	env GOOS=linux   GOARCH=arm   GOARM=7 go build -trimpath -o dist/$(DIST)/arm7    ./...
	env GOOS=darwin  GOARCH=amd64         go build -trimpath -o dist/$(DIST)/darwin  ./...
	env GOOS=windows GOARCH=amd64         go build -trimpath -o dist/$(DIST)/windows ./...

release: update-release build-all
	find . -name ".DS_Store" -delete
	tar --directory=dist --exclude=".DS_Store" -cvzf dist/$(DIST).tar.gz $(DIST)
	cd dist; zip --recurse-paths $(DIST).zip $(DIST)

debug: build
	# mqtt publish --topic 'uhppoted/gateway/requests/device/door/lock:open' \
 #               --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
 #                                                      "client-id":   "$(CLIENTID)",  \
 #                                                      "reply-to":    "$(REPLYTO)",   \
 #                                                      "device-id":   423187757,      \
 #                                                      "card-number": 6154410,        \
 #                                                      "door":        1 }}}'
debug2:
	mqtt publish --topic 'uhppoted/gateway/requests/device/event:get' \
               --message '{ "message": { "request": { "request-id":"$(REQUESTID)", \
                                                      "client-id":"$(CLIENTID)", \
                                                      "reply-to":"$(REPLYTO)", \
                                                      "device-id":423187757, \
                                                      "event-index": 206900 }}}'

	mqtt publish --topic 'uhppoted/gateway/requests/device/event:get' \

godoc:
	godoc -http=:80	-index_interval=60s

version: build
	./bin/uhppoted-mqtt version

help: build
	./bin/uhppoted-mqtt help
	./bin/uhppoted-mqtt help commands
	./bin/uhppoted-mqtt help version
	./bin/uhppoted-mqtt help run
	./bin/uhppoted-mqtt help daemonize
	./bin/uhppoted-mqtt help undaemonize
	./bin/uhppoted-mqtt help config

daemonize: build
	sudo ./bin/uhppoted-mqtt daemonize

undaemonize: build
	sudo ./bin/uhppoted-mqtt undaemonize

config: build
	./bin/uhppoted-mqtt config

run: build
	./bin/uhppoted-mqtt run --console

get-devices:
	mqtt publish --topic 'uhppoted/gateway/requests/devices:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "nonce":      5 }}}'

get-devices-hotp:
	mqtt publish --topic 'uhppoted/gateway/requests/devices:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "hotp":       "586787" }}}'

get-devices-rsa:
	mqtt publish --topic 'uhppoted/gateway/requests/devices:get' \
                 --message '{ "message": { "signature": "VXLQgzQOHnjIFW6UFftWBYtdwluM3M7nbQD6fjLdSkuk/L8ahLfHsIEPCQF9ofkqEGaBG2Dl6QJtqYF825z8dLPsxbQA1bgMrdbpiVKiS09Vn4ubONIGmShQKcuoZuAzgsVeNbCsDW2MhSq/f6W/DUlKmD9PwgxMkzeKUCjM8bQ=",\
                                           "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "nonce":      8 }}}'

get-device:
	mqtt publish --topic 'uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "device-id":  $(SERIALNO) }}}'

get-device-hotp:
	mqtt publish --topic 'uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "hotp":       "586787", \
                                                        "nonce":      8, \
                                                        "device-id":  $(SERIALNO) }}}'

get-device-rsa:
	mqtt publish --topic 'uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "signature": "Dd6qGX0lvKA4i0jltpZry1K6hePCATuC0L1Pv7YkHtTNb9cqP+CI4lTOVlq5uWnKB0kVfqdLSGa6dsCRzzw3VFqojhC1ZG8rQtpg4iFno7S73g7O6jF/UEfQ6jHqwubrxcZI8W2P9bcO5f7UR6aiZt6+/nHJlPTLycQ1jlNeM3c=",\
                                           "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "nonce":      8, \
                                                        "device-id":  $(SERIALNO) }}}'
get-device-encrypted:
	mqtt publish --topic 'uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "key":       "LRtq7KaKvsCP8VvaRXRsoc2+R5T8fhZ1x/cjFpknQmEbrtYmxe/5t1MSbRl2BxFRnEvCuGk6n64govDWcTvi58gU2Xn1XIQLOdBlg7Rk5bluEHdwM+nWRVqSBGTBe1UbvKbzeJ8Vm7jCFbYNVeBYDHRTgkfAnb4vpM/3KjYVDXlGLHO75ou16XPSNXyEvKwZUY5mKeAuS6O7igPkwkhdOgI4wUIBeqiKq5710pyOxitCv1b3CJvpo3lUIrwkGVNFn2fEUAEN3kCQUPpAxKeMOazEsRuQHJEm/thbFWIt0HrWE/XuqHtZZU17oAXiIgKioSUUJ6+cpXursNJWmI3nSQ==", \
                                           "signature": "G/3cEtzhZ+5iyms3sWYbh842ZbHYpJxKDrY8whkhlDmlXZis+P2l7PCfSH8l9hIeGvKUvIwL+wrkPkFwIZbNRJ0oYX9F1SXNVyEzjsKZZ6x4dJ57LnyK/YB8ygx/EBsESsSRo81QiBBD7XAHpKgVB/uqRTk9Tgq6J1YLYzyahv8=",\
                                           "request": "EJo5lNjfYl/aSBF2LodYrOpdWISCN4RfsFykVCu3K+OEeXI1r7QouxEwjLvZgsFUH2fK7qehUVyYtcoRdxdin0XS65t1P+Oc7dcrncyfHiJfRjbekEZqXpCG3Z02uTUtl4zss/Z8IAFxdjDmDB0NxsGALgCqhU70dioJgxeFqPyd3uHZi91dlvcWF2nf+Vb+6REEaSCCAEyQQ3BZ/NJUCQ==" \
                                         }, \
                              "hmac": "5a0d5ffdafc73f8f386e6673faf93b77ca64b8e9ec665a770efacb64258bba27" }'

get-device-encrypted-old:
	mqtt publish --topic 'uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "key":       "LRtq7KaKvsCP8VvaRXRsoc2+R5T8fhZ1x/cjFpknQmEbrtYmxe/5t1MSbRl2BxFRnEvCuGk6n64govDWcTvi58gU2Xn1XIQLOdBlg7Rk5bluEHdwM+nWRVqSBGTBe1UbvKbzeJ8Vm7jCFbYNVeBYDHRTgkfAnb4vpM/3KjYVDXlGLHO75ou16XPSNXyEvKwZUY5mKeAuS6O7igPkwkhdOgI4wUIBeqiKq5710pyOxitCv1b3CJvpo3lUIrwkGVNFn2fEUAEN3kCQUPpAxKeMOazEsRuQHJEm/thbFWIt0HrWE/XuqHtZZU17oAXiIgKioSUUJ6+cpXursNJWmI3nSQ==", \
                                           "iv":        "109A3994D8DF625FDA4811762E8758AC",\
                                           "signature": "G/3cEtzhZ+5iyms3sWYbh842ZbHYpJxKDrY8whkhlDmlXZis+P2l7PCfSH8l9hIeGvKUvIwL+wrkPkFwIZbNRJ0oYX9F1SXNVyEzjsKZZ6x4dJ57LnyK/YB8ygx/EBsESsSRo81QiBBD7XAHpKgVB/uqRTk9Tgq6J1YLYzyahv8=",\
                                           "request": "6l1YhII3hF+wXKRUK7cr44R5cjWvtCi7ETCMu9mCwVQfZ8rup6FRXJi1yhF3F2KfRdLrm3U/45zt1yudzJ8eIl9GNt6QRmpekIbdnTa5NS2XjOyz9nwgAXF2MOYMHQ3GwYAuAKqFTvR2KgmDF4Wo/J3e4dmL3V2W9xYXad/5Vv7pEQRpIIIATJBDcFn80lQJ" \
                                         }, \
                              "hmac": "46410fe2d18183452982ed22cec52dedf843436263d1097074454c3c30caa75a" }'


get-time:
	mqtt publish --topic 'uhppoted/gateway/requests/device/time:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "device-id":  $(SERIALNO) }}}'

set-time:
	mqtt publish --topic 'uhppoted/gateway/requests/device/time:set' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "device-id":  $(SERIALNO), \
                                                        "date-time":  "$(DATETIME)" }}}'

get-door-delay:
	mqtt publish --topic 'uhppoted/gateway/requests/device/door/delay:get' \
              --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                     "client-id":  "$(CLIENTID)", \
                                                     "reply-to":   "$(REPLYTO)", \
                                                     "device-id":  $(SERIALNO), \
                                                     "door":       3 }}}'

set-door-delay:
	mqtt publish --topic 'uhppoted/gateway/requests/device/door/delay:set' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO), \
                                                      "door":       3, \
                                                      "delay":      8 }}}'

get-door-control:
	mqtt publish --topic 'uhppoted/gateway/requests/device/door/control:get' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO), \
                                                      "door":       3 }}}'

set-door-control:
	mqtt publish --topic 'uhppoted/gateway/requests/device/door/control:set' \
              --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                     "client-id":  "$(CLIENTID)", \
                                                     "reply-to":   "$(REPLYTO)", \
                                                     "device-id":  $(SERIALNO), \
                                                     "door":       3, \
                                                     "control":    "normally closed" }}}'

record-special-events:
	mqtt publish --topic 'uhppoted/gateway/requests/device/special-events:set' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "device-id":  $(SERIALNO), \
                                                        "enabled":    true }}}'

get-status:
	mqtt publish --topic 'uhppoted/gateway/requests/device/status:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "device-id":  $(SERIALNO) }}}'

get-cards:
	mqtt publish --topic 'uhppoted/gateway/requests/device/cards:get' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                       "client-id": "$(CLIENTID)", \
                                                       "reply-to":  "$(REPLYTO)", \
                                                       "device-id": $(SERIALNO) }}}'

delete-cards:
	mqtt publish --topic 'uhppoted/gateway/requests/device/cards:delete' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO) }}}'

get-card:
	mqtt publish --topic 'uhppoted/gateway/requests/device/card:get' \
                 --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
                                                        "client-id":   "$(CLIENTID)", \
                                                        "reply-to":    "$(REPLYTO)", \
                                                        "device-id":   $(SERIALNO), \
                                                        "card-number": $(CARD) }}}'

put-card:
	mqtt publish --topic 'uhppoted/gateway/requests/device/card:put' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)",  \
                                                      "reply-to":   "$(REPLYTO)",   \
                                                      "device-id":  $(SERIALNO),    \
                                                      "card": { "card-number": $(CARD),      \
                                                                "start-date":  "2021-01-01", \
                                                                "end-date": "2021-12-31",    \
                                                                "doors": { "1":true, "2":false, "3":55, "4":false } } \
                                                    }}}'

delete-card:
	mqtt publish --topic 'uhppoted/gateway/requests/device/card:delete' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO), \
                                                      "card-number": $(CARD) }}}'

get-time-profile:
	mqtt publish --topic 'uhppoted/gateway/requests/device/time-profile:get' \
                 --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
                                                        "client-id":   "$(CLIENTID)", \
                                                        "reply-to":    "$(REPLYTO)", \
                                                        "device-id":   $(SERIALNO), \
                                                        "profile-id":  29 }}}'

set-time-profile:
	mqtt publish --topic 'uhppoted/gateway/requests/device/time-profile:set' \
                 --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
                                                        "client-id":   "$(CLIENTID)", \
                                                        "reply-to":    "$(REPLYTO)", \
                                                        "device-id":   $(SERIALNO), \
                                                        "profile":     { "id": 29, \
                                                                         "start-date": "2021-01-01", \
                                                                         "end-date":   "2021-12-31", \
                                                                         "weekdays":   "Monday,Wednesday,Thursday", \
                                                                         "segments": [ \
                                                                            { "start": "08:15", "end": "11:30" }, \
                                                                            { "start": "14:05", "end": "17:45" }  \
                                                                         ], \
                                                                         "linked-profile": 3 } \
                                                         }}}'

clear-time-profiles:
	mqtt publish --topic 'uhppoted/gateway/requests/device/time-profiles:delete'          \
                 --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
                                                        "client-id":   "$(CLIENTID)",  \
                                                        "reply-to":    "$(REPLYTO)",   \
                                                        "device-id":   $(SERIALNO) }}}'

get-time-profiles:
	mqtt publish --topic 'uhppoted/gateway/requests/device/time-profiles:get'          \
                 --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
                                                        "client-id":   "$(CLIENTID)",  \
                                                        "reply-to":    "$(REPLYTO)",   \
                                                        "device-id":   $(SERIALNO),    \
                                                        "from":        2,            \
                                                        "to":          254 }}}'

set-time-profiles:
	mqtt publish --topic 'uhppoted/gateway/requests/device/time-profiles:set'          \
                 --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
                                                        "client-id":   "$(CLIENTID)",  \
                                                        "reply-to":    "$(REPLYTO)",   \
                                                        "device-id":   $(SERIALNO),    \
                                                        "profiles":    [ \
                                                                         { "id": 29, \
                                                                         "start-date": "2021-01-01", \
                                                                         "end-date":   "2021-12-31", \
                                                                         "weekdays":   "Monday,Wednesday,Thursday", \
                                                                         "segments": [ \
                                                                            { "start": "08:15", "end": "11:30" }, \
                                                                            { "start": "14:05", "end": "17:45" }  \
                                                                         ], \
                                                                         "linked-profile": 30 }, \
                                                                         { "id": 31, \
                                                                         "start-date": "2021-01-01", \
                                                                         "end-date":   "2021-12-31", \
                                                                         "weekdays":   "Monday,Wednesday,Thursday", \
                                                                         "segments": [ \
                                                                            { "start": "08:15", "end": "11:30" }, \
                                                                            { "start": "14:05", "end": "17:45" }  \
                                                                         ], \
                                                                         "linked-profile": 32 }, \
                                                                         { "id": 32, \
                                                                         "start-date": "2021-01-01", \
                                                                         "end-date":   "2021-12-31", \
                                                                         "weekdays":   "Monday,Wednesday", \
                                                                         "segments": [ \
                                                                            { "start": "08:30", "end": "15:30" } \
                                                                         ], \
                                                                         "linked-profile": 33 }, \
                                                                         { "id": 33, \
                                                                         "start-date": "2021-01-01", \
                                                                         "end-date":   "2021-12-31", \
                                                                         "weekdays":   "Saturday,Sunday", \
                                                                         "segments": [ \
                                                                            { "start": "10:30", "end": "17:30" } \
                                                                         ]} \
                                                                       ]\
                                                         }}}'

set-task-list:
	mqtt publish --topic 'uhppoted/gateway/requests/device/tasklist:set'               \
                 --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
                                                        "client-id":   "$(CLIENTID)",  \
                                                        "reply-to":    "$(REPLYTO)",   \
                                                        "device-id":   $(SERIALNO),    \
                                                        "tasks":       [ \
                                                                         { \
                                                                           "task": "trigger once",     \
                                                                           "door": 3,                  \
                                                                           "start-date": "2021-01-01", \
                                                                           "end-date":   "2021-12-31", \
                                                                           "weekdays":   "Monday,Wednesday,Friday", \
                                                                           "start":      "08:27" \
                                                                         } \
                                                                       ]\
                                                         }}}'

get-events:
	mqtt publish --topic 'uhppoted/gateway/requests/device/events:get' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO) }}}'

	mqtt publish --topic 'uhppoted/gateway/requests/device/events:get' \
               --message '{ "message": { "request": { "request-id":"$(REQUESTID)", \
                                                      "client-id":"$(CLIENTID)", \
                                                      "reply-to":"$(REPLYTO)", \
                                                      "device-id":$(SERIALNO), \
                                                      "count": 3 }}}'

get-event:
	mqtt publish --topic 'uhppoted/gateway/requests/device/event:get' \
               --message '{ "message": { "request": { "request-id":"$(REQUESTID)", \
                                                      "client-id":"$(CLIENTID)", \
                                                      "reply-to":"$(REPLYTO)", \
                                                      "device-id":$(SERIALNO), \
                                                      "event-index": 50 }}}'

	mqtt publish --topic 'uhppoted/gateway/requests/device/event:get' \
               --message '{ "message": { "request": { "request-id":"$(REQUESTID)", \
                                                      "client-id":"$(CLIENTID)", \
                                                      "reply-to":"$(REPLYTO)", \
                                                      "device-id":$(SERIALNO), \
                                                      "event-index": "first" }}}'

	mqtt publish --topic 'uhppoted/gateway/requests/device/event:get' \
               --message '{ "message": { "request": { "request-id":"$(REQUESTID)", \
                                                      "client-id":"$(CLIENTID)", \
                                                      "reply-to":"$(REPLYTO)", \
                                                      "device-id":$(SERIALNO), \
                                                      "event-index": "last" }}}'

	mqtt publish --topic 'uhppoted/gateway/requests/device/event:get' \
               --message '{ "message": { "request": { "request-id":"$(REQUESTID)", \
                                                      "client-id":"$(CLIENTID)", \
                                                      "reply-to":"$(REPLYTO)", \
                                                      "device-id":$(SERIALNO), \
                                                      "event-index": "current" }}}'

	mqtt publish --topic 'uhppoted/gateway/requests/device/event:get' \
               --message '{ "message": { "request": { "request-id":"$(REQUESTID)", \
                                                      "client-id":"$(CLIENTID)", \
                                                      "reply-to":"$(REPLYTO)", \
                                                      "device-id":$(SERIALNO), \
                                                      "event-index": "next" }}}'

open-door:
	mqtt publish --topic 'uhppoted/gateway/requests/device/door/lock:open' \
               --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
                                                      "client-id":   "$(CLIENTID)",  \
                                                      "reply-to":    "$(REPLYTO)",   \
                                                      "device-id":   $(SERIALNO),    \
                                                      "card-number": $(CARD),        \
                                                      "door":        3 }}}'

acl-show:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/card:show' \
                 --message '{ "message": { "request": { \
                                           "card-number": 8165538, \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-grant:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/card:grant'    \
                 --message '{ "message": { "request": {                \
                                           "card-number": 8165538,     \
                                           "start-date": "2021-01-01", \
                                           "end-date": "2021-12-31",   \
                                           "doors": [ "Gryffindor", "Slytherin" ], \
                                           "client-id": "QWERTY54",              \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'
	mqtt publish --topic 'uhppoted/gateway/requests/acl/card:grant'    \
                 --message '{ "message": { "request": {                \
                                           "card-number": 8165538,     \
                                           "start-date": "2021-01-01", \
                                           "end-date": "2021-12-31",   \
                                           "profile": 29,              \
                                           "doors": [ "Dungeon" ], \
                                           "client-id": "QWERTY54",              \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-revoke:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/card:revoke' \
                 --message '{ "message": { "request": { \
                                           "card-number": 8165538, \
                                           "start-date": "2020-01-01", \
                                           "end-date": "2020-12-31", \
                                           "doors": [ "Dungeon" ], \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-upload-file:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/acl:upload' \
                 --message '{ "message": { "request": { \
                                           "url": "file://../runtime/mqttd/uhppoted.tar.gz", \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-upload-s3:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/acl:upload' \
                 --message '{ "message": { "request": { \
                                           "url": "s3://uhppoted-test/mqttd/uhppoted.tar.gz", \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-upload-http:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/acl:upload' \
                 --message '{ "message": { "request": { \
                                           "url": "http://localhost:8080/upload/mqttd.tar.gz", \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-download-file:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/acl:download' \
                 --message '{ "message": { "request": { \
                                           "url": "file://../runtime/mqttd/hogwarts.tar.gz", \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-download-s3:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/acl:download' \
                 --message '{ "message": { "request": { \
                                           "url": "s3://uhppoted-test/mqttd/QWERTY54.tar.gz", \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-download-http:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/acl:download' \
                 --message '{ "message": { "request": { \
                                           "url": "https://github.com/uhppoted/uhppoted/blob/master/runtime/simulation/QWERTY54.tar.gz?raw=true", \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-compare-file:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/acl:compare' \
                 --message '{ "message": { "request": { \
                                           "url": { \
                                           	"acl": "file://../runtime/mqttd/QWERTY54.tar.gz", \
                                           	"report": "file://../runtime/mqttd/report.tar.gz" \
                                           	}, \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-compare-s3:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/acl:compare' \
                 --message '{ "message": { "request": { \
                                           "url": { \
                                           	"acl": "s3://uhppoted-test/mqttd/QWERTY54.tar.gz", \
                                           	"report": "s3://uhppoted-test/mqttd/report.tar.gz" \
                                           	}, \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

acl-compare-http:
	mqtt publish --topic 'uhppoted/gateway/requests/acl/acl:compare' \
                 --message '{ "message": { "request": { \
                                           "url": { \
                                           	"acl": "https://github.com/uhppoted/uhppoted/blob/master/runtime/simulation/QWERTY54.tar.gz?raw=true", \
                                           	"report": "http://localhost:8080/upload/report.tar.gz" \
                                           	}, \
                                           "client-id": "QWERTY54", \
                                           "reply-to": "uhppoted\/reply\/97531", \
                                           "request-id": "AH173635G3" }}}'

