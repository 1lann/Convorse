package controllers

import (
	"github.com/revel/revel"
	// "convorse/database"
)

type Setup struct {
	*revel.Controller
}

func (c Setup) Index() revel.Result {
	return c.Render()
}

func init() {
	revel.InterceptMethod(Lobby.checkDatabase, revel.BEFORE)
}
