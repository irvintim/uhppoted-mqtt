package auth

import (
	"sync"
	"testing"
	"uhppoted/kvs"
)

func TestValidateHOTPWithValidOTP(t *testing.T) {
	hotp := HOTP{
		Enabled:   true,
		increment: 8,
		secrets:   kvs.NewKeyValueStore("test", func(v string) (interface{}, error) { return v, nil }),
		counters: struct {
			counters map[string]uint64
			filepath string
			guard    sync.Mutex
		}{
			counters: map[string]uint64{"qwerty": 1},
			filepath: "",
			guard:    sync.Mutex{},
		},
	}

	hotp.secrets.Put("qwerty", "DFIOJ3BJPHPCRJBT")

	if err := hotp.Validate("qwerty", "644039"); err != nil {
		t.Errorf("HOTP refused valid OTP")
	}

	if err := hotp.Validate("qwerty", "586787"); err != nil {
		t.Errorf("HOTP refused valid OTP")
	}
}

func TestValidateHOTPWithOutOfOrderOTP(t *testing.T) {
	hotp := HOTP{
		Enabled:   true,
		increment: 8,
		secrets:   kvs.NewKeyValueStore("test", func(v string) (interface{}, error) { return v, nil }),
		counters: struct {
			counters map[string]uint64
			filepath string
			guard    sync.Mutex
		}{
			counters: map[string]uint64{"qwerty": 1},
			filepath: "",
			guard:    sync.Mutex{},
		},
	}

	hotp.secrets.Put("qwerty", "DFIOJ3BJPHPCRJBT")

	if err := hotp.Validate("qwerty", "586787"); err != nil {
		t.Errorf("HOTP refused valid OTP")
	}

	if err := hotp.Validate("qwerty", "644039"); err == nil {
		t.Errorf("HOTP accepted out of order OTP")
	}
}

func TestValidateHOTPWithOutOfRangeOTP(t *testing.T) {
	hotp := HOTP{
		Enabled:   true,
		increment: 2,
		secrets:   kvs.NewKeyValueStore("test", func(v string) (interface{}, error) { return v, nil }),
		counters: struct {
			counters map[string]uint64
			filepath string
			guard    sync.Mutex
		}{
			counters: map[string]uint64{"qwerty": 1},
			filepath: "",
			guard:    sync.Mutex{},
		},
	}

	hotp.secrets.Put("qwerty", "DFIOJ3BJPHPCRJBT")

	if err := hotp.Validate("qwerty", "586787"); err == nil {
		t.Errorf("HOTP accepted out of range OTP")
	}
}

func TestValidateHOTPWithInvalidOTP(t *testing.T) {
	hotp := HOTP{
		Enabled:   true,
		increment: 8,
		secrets:   kvs.NewKeyValueStore("test", func(v string) (interface{}, error) { return v, nil }),
		counters: struct {
			counters map[string]uint64
			filepath string
			guard    sync.Mutex
		}{
			counters: map[string]uint64{"qwerty": 1},
			filepath: "",
			guard:    sync.Mutex{},
		},
	}

	hotp.secrets.Put("qwerty", "DFIOJ3BJPHPCRJBT")

	if err := hotp.Validate("qwerty", "644038"); err == nil {
		t.Errorf("HOTP accepted invalid OTP")
	}
}
