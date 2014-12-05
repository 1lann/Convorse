package serialize

import (
	"strconv"
	"strings"
	"reflect"
)

func parseInterface(input interface{}) (string) {
	switch value := input.(type) {
	case int:
		return strconv.Itoa(value)
	case int64:
		return strconv.FormatInt(value, 10)
	case float64:
		return strconv.FormatFloat(value, 'f', 6, 64)
	case string:
		return "\"" + strings.Replace(value, "\"", "\\\"", -1) + "\""
	case map[string]interface{}:
		return Serialize(value)
	case []interface{}:
		return ArraySerialize(value)
	default:
		return StructSerialize(value)
	}
}

func StructSerialize(input interface{}) (string) {
	serializedString := "{"

	str := reflect.ValueOf(input).Elem()

	typeStr := str.Type()
	for i := 0; i < str.NumField(); i++ {
		f := str.Field(i)
		serializedString = serializedString + "[\"" + strings.ToLower(typeStr.Field(i).Name) + "\"] = "
		serializedString = serializedString + parseInterface(f.Interface()) + ", "
	}

	return serializedString + "}"
}

func ArraySerialize(input []interface{}) (string) {
	serializedString := "{"
	for k, v := range input {
		serializedString = serializedString + "[" + strconv.Itoa(k + 1) + "] = " + parseInterface(v) + ", "
	}
	return serializedString + "}"
}

func Serialize(input map[string]interface{}) (string) {
	serializedString := "{"
	for k, v := range input {
		serializedString = serializedString + "[\"" + k + "\"] = " + parseInterface(v) + ", "
	}
	return serializedString + "}"
}
