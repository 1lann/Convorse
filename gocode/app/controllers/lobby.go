package controllers

import (
	"github.com/revel/revel"
	"convorse/database"
)

type Lobby struct {
	*revel.Controller
}

// if (strings.Contains(r.UserAgent(), "Java")) {
// 	fmt.Fprintf(w, "This is computercraft!");
// } else {
// 	fmt.Fprintf(w, "This is a browser!");
// }

func (c Lobby) LoginAction(username string, password string) revel.Result {
	if !database.DatabaseConnected{
		c.RenderArgs["databaseError"] = database.DatabaseConnected;
		go database.Connect()
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}

	result := database.VerifyLogin(username, password)

	if (result == database.Yes) {
		return c.RenderText("OK")
	} else if (result == database.No) {
		return c.RenderText("NOT OK")
	} else {
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}
}

func (c Lobby) Index() revel.Result {
	if !database.DatabaseConnected {
		c.RenderArgs["databaseError"] = database.DatabaseConnected;
		go database.Connect()
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}

	return c.Render()
}

func (c Lobby) Register(username string, email string, password string, password_again string) revel.Result {
	if !database.DatabaseConnected {
		c.RenderArgs["databaseError"] = database.DatabaseConnected;
		go database.Connect()
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}

	return c.Render()
}
