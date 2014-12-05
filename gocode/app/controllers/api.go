package controllers

import (
	"github.com/revel/revel"
	// "convorse/database"
	"convorse/serialize"
)

type Api struct {
	*revel.Controller
}

func (c Api) Conversation(conversation string) revel.Result {
	return c.Render()
}

func (c Api) Unread() revel.Result {
	return c.Render()
}

func (c Api) Post() revel.Result {
	return c.Render()
}

func (c Api) ConversationUsername() revel.Result {

}

func (c Api) checkDatabase() revel.Result {
	if !database.DatabaseConnected {
		go database.Connect()
		return c.RenderText("database-error")
	}
	return nil
}

func (c Api) checkLogin(username string, password string) revel.Result {
	if len(username) <= 0 {
		return c.RenderText("auth-fail", "Username required")
	}
	if len(password) <= 0 {
		return c.RenderText("auth-fail")
	}
}

func init() {
	revel.InterceptMethod(Api.checkDatabase, revel.BEFORE)
	revel.InterceptMethod(Api.checkLogin, revel.BEFORE)
}
