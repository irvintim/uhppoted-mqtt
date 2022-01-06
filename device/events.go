package device

import (
	"fmt"
	"regexp"
	"strconv"

	"github.com/uhppoted/uhppoted-lib/uhppoted"
	"github.com/uhppoted/uhppoted-mqtt/common"
)

// Handler for the special-events MQTT message. Extracts the 'enabled' value from the request
// and invokes the uhppoted-lib.RecordSpecialEvents API function to update the controller
// 'record special events' flag.
func (d *Device) RecordSpecialEvents(impl uhppoted.IUHPPOTED, request []byte) (interface{}, error) {
	body := struct {
		DeviceID *uhppoted.DeviceID `json:"device-id"`
		Enabled  *bool              `json:"enabled"`
	}{}

	if response, err := unmarshal(request, &body); err != nil {
		return response, err
	}

	if body.DeviceID == nil {
		return common.MakeError(StatusBadRequest, "Invalid/missing device ID", nil), fmt.Errorf("Invalid/missing device ID")
	}

	if body.Enabled == nil {
		return common.MakeError(StatusBadRequest, "Invalid/missing 'enabled'", nil), fmt.Errorf("Invalid/missing 'enabled'")
	}

	rq := uhppoted.RecordSpecialEventsRequest{
		DeviceID: *body.DeviceID,
		Enable:   *body.Enabled,
	}

	response, err := impl.RecordSpecialEvents(rq)
	if err != nil {
		return common.MakeError(StatusInternalServerError, fmt.Sprintf("Could not update 'record special events' flag for %d", *body.DeviceID), err), err
	}

	if response == nil {
		return nil, nil
	}

	return response, nil
}

func (d *Device) GetEventIndices(impl uhppoted.IUHPPOTED, request []byte) (interface{}, error) {
	body := struct {
		DeviceID uint32 `json:"device-id"`
	}{}

	if response, err := unmarshal(request, &body); err != nil {
		return response, err
	}

	if body.DeviceID == 0 {
		return common.MakeError(StatusBadRequest, "Invalid/missing device ID", nil), fmt.Errorf("Invalid/missing device ID")
	}

	first, last, current, err := impl.GetEventIndices(body.DeviceID)
	if err != nil {
		return common.MakeError(StatusInternalServerError, fmt.Sprintf("Could not retrieve events from %d", body.DeviceID), err), err
	}

	response := struct {
		DeviceID uint32 `json:"device-id,omitempty"`
		First    uint32 `json:"first,omitempty"`
		Last     uint32 `json:"last,omitempty"`
		Current  uint32 `json:"current,omitempty"`
	}{
		DeviceID: body.DeviceID,
		First:    first,
		Last:     last,
		Current:  current,
	}

	return response, nil
}

func (d *Device) GetEvent(impl uhppoted.IUHPPOTED, request []byte) (interface{}, error) {
	var deviceID uint32
	var index string

	body := struct {
		DeviceID uint32      `json:"device-id"`
		Index    interface{} `json:"event-index"`
	}{}

	if response, err := unmarshal(request, &body); err != nil {
		return response, err
	}

	if body.DeviceID == 0 {
		return common.MakeError(StatusBadRequest, "Invalid/missing device ID", nil), fmt.Errorf("Invalid/missing device ID")
	} else {
		deviceID = body.DeviceID
	}

	if body.Index == nil {
		return common.MakeError(StatusBadRequest, "Invalid/missing event index", nil), fmt.Errorf("Invalid/missing event index")
	}

	// ... parse event index

	if matches := regexp.MustCompile("^([0-9]+|first|last|current|next)$").FindStringSubmatch(fmt.Sprintf("%v", body.Index)); matches == nil {
		return common.MakeError(StatusBadRequest, "Invalid/missing event index", nil), fmt.Errorf("Invalid/missing event index")
	} else {
		index = matches[1]
	}

	// .. get event indices
	first, last, current, err := impl.GetEventIndices(deviceID)
	if err != nil {
		return common.MakeError(StatusInternalServerError, fmt.Sprintf("Could not retrieve event indices from %v", deviceID), err), err
	}

	// ... get event
	switch index {
	case "first":
		return getEvent(impl, deviceID, first)

	case "last":
		return getEvent(impl, deviceID, last)

	case "current":
		return getEvent(impl, deviceID, current)

	case "next":
		return getNextEvent(impl, deviceID)

	default:
		if v, err := strconv.ParseUint(index, 10, 32); err != nil {
			return common.MakeError(StatusBadRequest, fmt.Sprintf("Invalid event index (%v)", body.Index), nil), fmt.Errorf("Invalid event index (%v)", index)
		} else {
			return getEvent(impl, deviceID, uint32(v))
		}
	}
}

func getEvent(impl uhppoted.IUHPPOTED, deviceID uint32, index uint32) (interface{}, error) {
	event, err := impl.GetEvent(deviceID, index)
	if err != nil {
		return common.MakeError(StatusInternalServerError, fmt.Sprintf("Could not retrieve event %v from %v", index, deviceID), err), err
	} else if event == nil {
		return common.MakeError(StatusNotFound, fmt.Sprintf("No event at %v on %v", index, deviceID), nil), fmt.Errorf("No event at %v on %v", index, deviceID)
	}

	response := struct {
		DeviceID uint32      `json:"device-id"`
		Event    interface{} `json:"event"`
	}{
		DeviceID: deviceID,
		Event:    event,
	}

	return &response, nil
}

func getNextEvent(impl uhppoted.IUHPPOTED, deviceID uint32) (interface{}, error) {
	event, err := impl.GetEvents(deviceID, 1)
	if err != nil {
		return common.MakeError(StatusInternalServerError, fmt.Sprintf("Could not retrieve event from %v", deviceID), err), err
	} else if event == nil {
		return common.MakeError(StatusNotFound, fmt.Sprintf("No 'next' event for %v", deviceID), nil), fmt.Errorf("No 'next' event for %v", deviceID)
	}

	response := struct {
		DeviceID uint32      `json:"device-id"`
		Event    interface{} `json:"event"`
	}{
		DeviceID: deviceID,
		Event:    event,
	}

	return &response, nil
}
