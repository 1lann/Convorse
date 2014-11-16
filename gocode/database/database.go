package database

import (
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
	"fmt"
	"crypto/sha256"
	"encoding/hex"
	"time"
)

// type Item struct {
// 	Name string
// 	Id string
// 	ImageName string
// 	Gallery []string
// 	Category string
// 	Price float32
// 	Stock int
// 	FlagForDelete bool
// 	Description string
// }
//
// type ItemDBManager struct {
// 	all map[string]*Item
// }
//
// var ItemDB ItemDBManager
//
// func (items *ItemDBManager) GetUniqueItemID() string {
// 	for {
// 		result := uniuri.NewLen(4)
// 		if _, exists := items.all[result]; !exists {
// 			return result
// 		}
// 	}
// }

var accounts *mgo.Collection
var activeSession *mgo.Session
var isConnecting bool
var isChecking bool
var DatabaseConnected bool

const (
	Yes   = 1
	No    = 2
	Error = 3
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
}

func AccountExists(username string) int {
	result := Account{}

	err := accounts.Find(bson.M{"username": username}).One(&result)

	if err != nil {
		if err.Error() == "not found" {
			return No
		} else if err.Error() == "EOF" {
			activeSession.Close()
			return Error
		}
		return Error
	}

	return Yes
}

func VerifyLogin(username string, password string) int {
	hasher := sha256.New()
	hasher.Write([]byte(password + passwordSalt))
	hash := hex.EncodeToString(hasher.Sum(nil))

	result := Account{}
	err := accounts.Find(bson.M{"username": username, "hash": hash}).One(&result)

	if err != nil {
		if err.Error() == "not found" {
			return No
		} else if err.Error() == "EOF" {
			activeSession.Close()
			return Error
		}
		fmt.Println("Failed to search database")
		return Error
	}

	return Yes
}

func Connect() bool {
	if !isConnecting {
		isConnecting = true
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
