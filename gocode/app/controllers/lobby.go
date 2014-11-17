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

	accountExists := database.AccountExists(username)

	if accountExists == nil {
		result := database.VerifyLogin(username, password)

		if (result == nil) {
			return c.RenderText("OK")
		} else if (result == "not found") {
			c.Validation.Error("Incorrect passsword!").Key("password")
			c.Validation.Keep()
			c.FlashParams()
			return c.Redirect("/")
		} else {
			return c.RenderTemplate("errors/database."+c.Request.Format)
		}
	} else if accountExists.Error() == "not found" {
		c.Validation.Error("That user does not exist!").Key("username")
		c.Validation.Keep()
		c.FlashParams()
		return c.Redirect("/")
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

func (c Lobby) Register() revel.Result {
	if !database.DatabaseConnected {
		c.RenderArgs["databaseError"] = database.DatabaseConnected;
		go database.Connect()
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}

	return c.Render()
}

func (c Lobby) RegisterAction(username string, email string, password string, password_again string) revel.Result {
	if !database.DatabaseConnected {
		c.RenderArgs["databaseError"] = database.DatabaseConnected;
		go database.Connect()
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}

	c.Validation.MinSize(username, 3).Message("Username must be at least 3 characters long")
	c.Validation.MaxSize(username, 20).Message("Username cannot be longer than 20 characters")
	c.Validation.MinSize(password, 5).Message("Password must be at least 5 characters long")
	c.Validation.MaxSize(password, 50).Message("Password cannot be longer than 50 characters")
	c.Validation.Required(password == password_again).Message("Passwords aren't the same").Key("password")

	if (len(email) > 0) {
		c.Validation.Email(email).Message("Optional email must be valid")
	}

	if c.Validation.HasErrors() {
		c.Validation.Keep()
		c.FlashParams()
		return c.Redirect("/register")
	}

	exists := database.AccountExists(username)

	if exists == "not found" {
		result := database.RegisterAccount(username, email, password)
		if result == nil {
			return c.RenderText("Account created!")
		} else {
			return c.RenderTemplate("errors/database."+c.Request.Format)
		}
	} else if exists == nil {
		c.Validation.Error("Username already taken!").Key("username")
		c.Validation.Keep()
		c.FlashParams()
		return c.Redirect("/register")
	} else {
		return c.RenderTemplate("errors/database."+c.Request.Format)
	}
}
