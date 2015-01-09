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

const noErrorMessage = "no_error_message"

func (c Lobby) LoginAction(a_username string, b_password string) revel.Result {
	accountExists := database.AccountExists(a_username)

	if accountExists == database.Yes {
		result := database.VerifyLogin(a_username, b_password)

		if (result == database.Yes) {
			return c.RenderText("OK")
		} else if (result == database.No) {
			c.Validation.Error("Incorrect password (or username!)").Key("a_username")
			c.Validation.Error(noErrorMessage).Key("b_password")
			c.Validation.Keep()
			c.FlashParams()
			return c.Redirect("/")
		} else {
			return c.RenderTemplate("errors/database."+c.Request.Format)
		}
	} else if accountExists == database.No {
		c.Validation.Error("That user does not exist!").Key("a_username")
		c.Validation.Keep()
		c.FlashParams()
		return c.Redirect("/")
	} else {
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}
}

func (c Lobby) Index() revel.Result {
	return c.Render()
}

func (c Lobby) Register() revel.Result {
	return c.Render()
}

func (c Lobby) RegisterAction(a_username string, b_password string, c_password_again string) revel.Result {
	c.Validation.MinSize(a_username, 3).Message("Username must be at least 3 characters long")
	c.Validation.MaxSize(a_username, 20).Message("Username cannot be longer than 20 characters")
	c.Validation.MinSize(b_password, 5).Message("Password must be at least 5 characters long")
	c.Validation.MaxSize(b_password, 50).Message("Password cannot be longer than 50 characters")
	c.Validation.Required(b_password == c_password_again).Message("Passwords aren't the same").Key("b_password")

	exists := database.AccountExists(a_username)

	if exists == database.No {
		if c.Validation.HasErrors() {
			c.Validation.Keep()
			c.FlashParams()
			return c.Redirect("/register")
		}
		result := database.RegisterAccount(a_username, b_password)
		if result == database.Yes {
			return c.RenderText("Account created!")
		} else {
			return c.RenderTemplate("errors/database."+c.Request.Format)
		}
	} else if exists == database.Yes {
		c.Validation.Error("Username already taken!").Key("a_username")
		c.Validation.Keep()
		c.FlashParams()
		return c.Redirect("/register")
	} else {
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}
}

func (c Lobby) checkDatabase() revel.Result {
	if !database.DatabaseConnected {
		c.RenderArgs["databaseError"] = database.DatabaseConnected;
		go database.Connect()
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}
	return nil
}

func init() {
	revel.InterceptMethod(Lobby.checkDatabase, revel.BEFORE)
	revel.TemplateFuncs["ismessage"] = func(a *revel.ValidationError) bool {
		return a.String() != noErrorMessage
	}
}
