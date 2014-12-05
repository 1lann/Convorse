package controllers

import (
	"github.com/revel/revel"
	// "convorse/database"
)

type Main struct {
	*revel.Controller
}

func (c Main) Home() revel.Result {
	return c.Render()
}

func init() {
	revel.InterceptMethod(Lobby.checkDatabase, revel.BEFORE)
}
