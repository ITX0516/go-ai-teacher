package handlers

import (
	"go_teacher/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type UserHandler struct {
	userService *services.UserService
}

func NewUserHandler(us *services.UserService) *UserHandler {
	return &UserHandler{userService: us}
}

func (h *UserHandler) GetProgress(c *gin.Context) {
	userID := c.Param("id")
	progress := h.userService.GetProgress(userID)
	if progress == nil {
		progress = h.userService.CreateUser(userID)
	}
	c.JSON(http.StatusOK, progress)
}

type recordGameRequest struct {
	Won bool `json:"won"`
}

func (h *UserHandler) RecordGame(c *gin.Context) {
	userID := c.Param("id")
	var req recordGameRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	progress := h.userService.RecordGame(userID, req.Won)
	c.JSON(http.StatusOK, progress)
}

func (h *UserHandler) RecordPuzzle(c *gin.Context) {
	userID := c.Param("id")
	progress := h.userService.RecordPuzzleSolved(userID)
	c.JSON(http.StatusOK, progress)
}

func (h *UserHandler) Login(c *gin.Context) {
	userID := c.Param("id")
	progress := h.userService.RecordLogin(userID)
	c.JSON(http.StatusOK, progress)
}

func (h *UserHandler) ListAchievements(c *gin.Context) {
	achievements := h.userService.GetAchievements()
	c.JSON(http.StatusOK, gin.H{"achievements": achievements})
}
