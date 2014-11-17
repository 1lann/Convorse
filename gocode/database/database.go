package database

import (
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
	"fmt"
	"crypto/sha256"
	"encoding/hex"
	"time"
	"strconv"
	"math"
)

var accounts *mgo.Collection
var activeSession *mgo.Session
var isConnecting bool
var isChecking bool
var DatabaseConnected bool

const (
	Yes        = 1
	No         = 2
	Error      = 3
	NotSet     = 4
)

// I know, know. Constant/static password salts are bad :(
// But they should be sufficient for the purposes of CC
// If the community grows (or I get hacked), I'll add more
// security features.
const passwordSalt = "convorse-password-salt"

type Account struct {
	Username string
	Email string
	Hash string
	Timezone int
}

type Conversation struct {
 	Id bson.ObjectId `bson:"_id,omitempty"`
	Members []string
	Group bool
	LastUpdate time.Time
}

type Message struct {
	ConversationID string
	Time time.Time
	Username string
	SystemMessage bool
	Content string
}

func HumanDateTime(eventTime time.Time, location *time.Location) (string, string) {
	hour, min, _ := eventTime.Clock()
	year, month, day := eventTime.Date()

	humanDate := strconv.Itoa(day) + " " + month.String() + " " + strconv.Itoa(year)
	var humanTime string
	var stringMin string

	if min < 10 {
		stringMin = "0" + strconv.Itoa(min)
	} else {
		stringMin = strconv.Itoa(min)
	}

	if hour == 12 {
		humanTime = "12:" + stringMin + " PM"
	} else if hour == 0 {
		humanTime = "12:" + stringMin + " AM"
	} else if hour > 12 {
		humanTime = strconv.Itoa(hour - 12) + ":" + stringMin + " PM"
	} else {
		humanTime = strconv.Itoa(hour) + ":" + stringMin + " AM"
	}

	return humanDate, humanTime
}

func HumanTimeSince(eventTime time.Time, location *time.Location) string {
	duration := time.Since(eventTime)
	if duration.Seconds() < 30 {
		return "just now"
	} else if duration.Seconds() < 60 {
		return "less than a minute ago"
	} else if duration.Minutes() < 60 {
		if int(duration.Minutes()) == 1 {
			return "1 minute ago"
		} else {
			return (strconv.Itoa(int(math.Floor(duration.Minutes() + 0.5))) + " minutes ago")
		}
	} else if duration.Hours() < 5 {
		if int(duration.Hours()) == 1 {
			return "1 hour ago"
		} else {
			return (strconv.Itoa(int(math.Floor(duration.Hours() + 0.5))) + " hours ago")
		}
	} else {
		_, humanTime := HumanDateTime(eventTime, location)
		return humanTime
	}
}

func AccountExists(username string) int {
	result := Account{}

	if err := accounts.Find(bson.M{"username": username}).One(&result); err != nil {
		if err.Error() == "not found" {
			return No
		} else if isDisconnected(err.Error()) {
			DatabaseConnected = false
			activeSession.Close()
		}
		return Error
	}

	return Yes
}

func GetEmail(username string) (int, string) {
	result := Account{}

	if err := accounts.Find(bson.M{"username": username}).One(&result); err != nil {
		if err.Error() == "not found" {
			return No, ""
		} else if isDisconnected(err.Error()) {
			DatabaseConnected = false
			activeSession.Close()
		}
		return Error, ""
	}

	if len(result.Email) > 0 {
		return Yes, result.Email
	}

	return NotSet, ""
}

func VerifyLogin(username string, password string) int {
	hasher := sha256.New()
	hasher.Write([]byte(password + passwordSalt))
	hash := hex.EncodeToString(hasher.Sum(nil))

	result := Account{}
	if err := accounts.Find(bson.M{"username": username, "hash": hash}).One(&result); err != nil {
		if err.Error() == "not found" {
			return No
		} else if isDisconnected(err.Error()) {
			DatabaseConnected = false
			activeSession.Close()
		}
		return Error
	}

	fmt.Println(result)
	return Yes
}

func RegisterAccount(username string, password string) int {
	hasher := sha256.New()
	hasher.Write([]byte(password + passwordSalt))
	hash := hex.EncodeToString(hasher.Sum(nil))

	result := Account{
		Username: username,
		Hash: hash,
	}

	if err := accounts.Insert(result); err != nil {
		return Error
	}

	return Yes
}


func isDisconnected(err string) bool {
	if err == "EOF" || err == "no reachable servers" {
		return true
	} else {
		return false
	}
}

func Connect() bool {
	if !isConnecting {
		isConnecting = true
		fmt.Println("Connecting...")
		session, err := mgo.DialWithTimeout("127.0.0.1", time.Second*3)
		if err != nil {
			isConnecting = false
			DatabaseConnected = false
			fmt.Println(err)
			return false
		}

		session.SetMode(mgo.Monotonic, true)
		session.SetSyncTimeout(time.Second*3)
		session.SetSocketTimeout(time.Second*3)

		if activeSession != nil {
			activeSession.Close()
		}

		activeSession = session

		accounts = session.DB("convorse").C("accounts")
		DatabaseConnected = true
		isConnecting = false
		return true
	} else {
		return false
	}
}

func init() {
	Connect()
}
