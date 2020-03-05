DEBUG ?= --debug
VERSION = v0.5.1
DIST   ?= development
LDFLAGS = -ldflags "-X uhppote.VERSION=$(VERSION)" 

SERIALNO  ?= 405419896
CARD      ?= 1x327679
REQUESTID ?= AH173635G3
CLIENTID  ?= QWERTY54
REPLYTO   ?= twystd/uhppoted/reply/97531

all: test      \
	 benchmark \
     coverage

clean:
	go clean
	rm -rf bin

format: 
	go fmt ./...

build: format
	mkdir -p bin
	go build -o bin ./...

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

release: test vet
	mkdir -p dist/$(DIST)/windows
	mkdir -p dist/$(DIST)/darwin
	mkdir -p dist/$(DIST)/linux
	mkdir -p dist/$(DIST)/arm7
	env GOOS=linux   GOARCH=amd64         go build -o dist/$(DIST)/linux   ./...
	env GOOS=linux   GOARCH=arm   GOARM=7 go build -o dist/$(DIST)/arm7    ./...
	env GOOS=darwin  GOARCH=amd64         go build -o dist/$(DIST)/darwin  ./...
	env GOOS=windows GOARCH=amd64         go build -o dist/$(DIST)/windows ./...

release-tar: release
	find . -name ".DS_Store" -delete
	tar --directory=dist --exclude=".DS_Store" -cvzf dist/$(DIST).tar.gz $(DIST)
	cd dist; zip --recurse-paths $(DIST).zip $(DIST)

debug: build
	go test ./...

version: build
	./bin/uhppoted-mqtt version

help: build
	./bin/uhppoted-mqtt help
	./bin/uhppoted-mqtt help commands
	./bin/uhppoted-mqtt help version
	./bin/uhppoted-mqtt help help

daemonize: build
	sudo ./bin/uhppoted-mqtt daemonize

undaemonize: build
	sudo ./bin/uhppoted-mqtt undaemonize

config: build
	./bin/uhppoted-mqtt config

run: build
	./bin/uhppoted-mqtt --console

get-devices:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/devices:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "nonce":      5 }}}'

get-devices-hotp:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/devices:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "hotp":       "586787" }}}'

get-devices-rsa:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/devices:get' \
                 --message '{ "message": { "signature": "VXLQgzQOHnjIFW6UFftWBYtdwluM3M7nbQD6fjLdSkuk/L8ahLfHsIEPCQF9ofkqEGaBG2Dl6QJtqYF825z8dLPsxbQA1bgMrdbpiVKiS09Vn4ubONIGmShQKcuoZuAzgsVeNbCsDW2MhSq/f6W/DUlKmD9PwgxMkzeKUCjM8bQ=",\
                                           "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "nonce":      8 }}}'

get-device:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "device-id":  $(SERIALNO) }}}'

get-device-hotp:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "hotp":       "586787", \
                                                        "nonce":      8, \
                                                        "device-id":  $(SERIALNO) }}}'

get-device-rsa:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "signature": "Dd6qGX0lvKA4i0jltpZry1K6hePCATuC0L1Pv7YkHtTNb9cqP+CI4lTOVlq5uWnKB0kVfqdLSGa6dsCRzzw3VFqojhC1ZG8rQtpg4iFno7S73g7O6jF/UEfQ6jHqwubrxcZI8W2P9bcO5f7UR6aiZt6+/nHJlPTLycQ1jlNeM3c=",\
                                           "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "nonce":      8, \
                                                        "device-id":  $(SERIALNO) }}}'
get-device-encrypted:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "key":       "LRtq7KaKvsCP8VvaRXRsoc2+R5T8fhZ1x/cjFpknQmEbrtYmxe/5t1MSbRl2BxFRnEvCuGk6n64govDWcTvi58gU2Xn1XIQLOdBlg7Rk5bluEHdwM+nWRVqSBGTBe1UbvKbzeJ8Vm7jCFbYNVeBYDHRTgkfAnb4vpM/3KjYVDXlGLHO75ou16XPSNXyEvKwZUY5mKeAuS6O7igPkwkhdOgI4wUIBeqiKq5710pyOxitCv1b3CJvpo3lUIrwkGVNFn2fEUAEN3kCQUPpAxKeMOazEsRuQHJEm/thbFWIt0HrWE/XuqHtZZU17oAXiIgKioSUUJ6+cpXursNJWmI3nSQ==", \
                                           "signature": "G/3cEtzhZ+5iyms3sWYbh842ZbHYpJxKDrY8whkhlDmlXZis+P2l7PCfSH8l9hIeGvKUvIwL+wrkPkFwIZbNRJ0oYX9F1SXNVyEzjsKZZ6x4dJ57LnyK/YB8ygx/EBsESsSRo81QiBBD7XAHpKgVB/uqRTk9Tgq6J1YLYzyahv8=",\
                                           "request": "EJo5lNjfYl/aSBF2LodYrOpdWISCN4RfsFykVCu3K+OEeXI1r7QouxEwjLvZgsFUH2fK7qehUVyYtcoRdxdin0XS65t1P+Oc7dcrncyfHiJfRjbekEZqXpCG3Z02uTUtl4zss/Z8IAFxdjDmDB0NxsGALgCqhU70dioJgxeFqPyd3uHZi91dlvcWF2nf+Vb+6REEaSCCAEyQQ3BZ/NJUCQ==" \
                                         }, \
                              "hmac": "5a0d5ffdafc73f8f386e6673faf93b77ca64b8e9ec665a770efacb64258bba27" }'

get-device-encrypted-old:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device:get' \
                 --message '{ "message": { "key":       "LRtq7KaKvsCP8VvaRXRsoc2+R5T8fhZ1x/cjFpknQmEbrtYmxe/5t1MSbRl2BxFRnEvCuGk6n64govDWcTvi58gU2Xn1XIQLOdBlg7Rk5bluEHdwM+nWRVqSBGTBe1UbvKbzeJ8Vm7jCFbYNVeBYDHRTgkfAnb4vpM/3KjYVDXlGLHO75ou16XPSNXyEvKwZUY5mKeAuS6O7igPkwkhdOgI4wUIBeqiKq5710pyOxitCv1b3CJvpo3lUIrwkGVNFn2fEUAEN3kCQUPpAxKeMOazEsRuQHJEm/thbFWIt0HrWE/XuqHtZZU17oAXiIgKioSUUJ6+cpXursNJWmI3nSQ==", \
                                           "iv":        "109A3994D8DF625FDA4811762E8758AC",\
                                           "signature": "G/3cEtzhZ+5iyms3sWYbh842ZbHYpJxKDrY8whkhlDmlXZis+P2l7PCfSH8l9hIeGvKUvIwL+wrkPkFwIZbNRJ0oYX9F1SXNVyEzjsKZZ6x4dJ57LnyK/YB8ygx/EBsESsSRo81QiBBD7XAHpKgVB/uqRTk9Tgq6J1YLYzyahv8=",\
                                           "request": "6l1YhII3hF+wXKRUK7cr44R5cjWvtCi7ETCMu9mCwVQfZ8rup6FRXJi1yhF3F2KfRdLrm3U/45zt1yudzJ8eIl9GNt6QRmpekIbdnTa5NS2XjOyz9nwgAXF2MOYMHQ3GwYAuAKqFTvR2KgmDF4Wo/J3e4dmL3V2W9xYXad/5Vv7pEQRpIIIATJBDcFn80lQJ" \
                                         }, \
                              "hmac": "46410fe2d18183452982ed22cec52dedf843436263d1097074454c3c30caa75a" }'


get-status:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/status:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "device-id":  $(SERIALNO) }}}'

get-time:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/time:get' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "device-id":  $(SERIALNO) }}}'

set-time:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/time:set' \
                 --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                        "client-id":  "$(CLIENTID)", \
                                                        "reply-to":   "$(REPLYTO)", \
                                                        "device-id":  $(SERIALNO), \
                                                        "date-time":  "$(DATETIME)" }}}'

get-door-delay:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/door/delay:get' \
              --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                     "client-id":  "$(CLIENTID)", \
                                                     "reply-to":   "$(REPLYTO)", \
                                                     "device-id":  $(SERIALNO), \
                                                     "door":       3 }}}'

set-door-delay:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/door/delay:set' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO), \
                                                      "door":       3, \
                                                      "delay":      8 }}}'

get-door-control:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/door/control:get' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO), \
                                                      "door":       3 }}}'

set-door-control:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/door/control:set' \
              --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                     "client-id":  "$(CLIENTID)", \
                                                     "reply-to":   "$(REPLYTO)", \
                                                     "device-id":  $(SERIALNO), \
                                                     "door":       3, \
                                                     "control":    "normally closed" }}}'

get-cards:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/cards:get' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                       "client-id": "$(CLIENTID)", \
                                                       "reply-to":  "$(REPLYTO)", \
                                                       "device-id": $(SERIALNO) }}}'

delete-cards:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/cards:delete' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO) }}}'

get-card:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/card:get' \
                 --message '{ "message": { "request": { "request-id":  "$(REQUESTID)", \
                                                        "client-id":   "$(CLIENTID)", \
                                                        "reply-to":    "$(REPLYTO)", \
                                                        "device-id":   $(SERIALNO), \
                                                        "card-number": "$(CARD)" }}}'

put-card:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/card:put' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO), \
                                                      "card": { "card-number": "$(CARD)", \
                                                                "valid-from":  "2020-01-01", \
                                                                "valid-until": "2020-12-31", \
                                                                "doors": [true,false,false,true] } \
                                                    }}}'

delete-card:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/card:delete' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO), \
                                                      "card-number": $(CARD) }}}'

get-events:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/events:get' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO), \
                                                      "start":      "2019-08-05", \
                                                      "end":        "2019-08-09" }}}'

get-event:
	mqtt publish --topic 'twystd/uhppoted/gateway/requests/device/event:get' \
               --message '{ "message": { "request": { "request-id": "$(REQUESTID)", \
                                                      "client-id":  "$(CLIENTID)", \
                                                      "reply-to":   "$(REPLYTO)", \
                                                      "device-id":  $(SERIALNO), \
                                                      "event-id":   50 }}}'
