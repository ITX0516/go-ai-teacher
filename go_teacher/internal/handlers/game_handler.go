package handlers

import (
	"go_teacher/internal/models"
	"go_teacher/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type GameHandler struct {
	gameService    *services.GameService
	kataGoService  *services.KataGoService
	kimiService    *services.KimiService
}

func NewGameHandler(gs *services.GameService, ks *services.KataGoService, kimi *services.KimiService) *GameHandler {
	return &GameHandler{
		gameService:   gs,
		kataGoService: ks,
		kimiService:   kimi,
	}
}

type newGameRequest struct {
	BoardSize int     `json:"board_size"`
	Komi      float64 `json:"komi"`
}

func (h *GameHandler) NewGame(c *gin.Context) {
	var req newGameRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.BoardSize == 0 {
		req.BoardSize = 19
	}
	if req.Komi == 0 {
		req.Komi = 6.5
	}
	gameID := c.Param("id")
	game := h.gameService.NewGame(gameID, req.BoardSize, req.Komi)
	c.JSON(http.StatusOK, gin.H{
		"game_id": gameID,
		"game":    services.GameStateToJSON(game),
	})
}

func (h *GameHandler) GetGame(c *gin.Context) {
	gameID := c.Param("id")
	game, ok := h.gameService.GetGame(gameID)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
		return
	}
	c.JSON(http.StatusOK, services.GameStateToJSON(game))
}

type playMoveRequest struct {
	X     int `json:"x"`
	Y     int `json:"y"`
	Color int `json:"color"`
}

func (h *GameHandler) PlayMove(c *gin.Context) {
	gameID := c.Param("id")
	var req playMoveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	color := models.Black
	if req.Color == 2 {
		color = models.White
	}
	game, err := h.gameService.PlayMove(gameID, req.X, req.Y, color)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	analysis, _ := h.kataGoService.AnalyzePosition(game)
	c.JSON(http.StatusOK, gin.H{
		"game":     services.GameStateToJSON(game),
		"analysis": analysis,
	})
}

type aiMoveRequest struct {
	Color      int    `json:"color"`
	Difficulty string `json:"difficulty"`
}

func (h *GameHandler) AIMove(c *gin.Context) {
	gameID := c.Param("id")
	var req aiMoveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Difficulty == "" {
		req.Difficulty = "medium"
	}
	game, ok := h.gameService.GetGame(gameID)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
		return
	}
	move, err := h.kataGoService.GetBestMove(game, req.Difficulty)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	x, y, err := services.MoveToCoord(move, game.BoardSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	stoneColor := models.Black
	if req.Color == 2 {
		stoneColor = models.White
	}
	updatedGame, err := h.gameService.PlayMove(gameID, x, y, stoneColor)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	analysis, _ := h.kataGoService.AnalyzePosition(updatedGame)
	c.JSON(http.StatusOK, gin.H{
		"move":     move,
		"x":        x,
		"y":        y,
		"game":     services.GameStateToJSON(updatedGame),
		"analysis": analysis,
	})
}

func (h *GameHandler) UndoMove(c *gin.Context) {
	gameID := c.Param("id")
	game, err := h.gameService.UndoMove(gameID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, services.GameStateToJSON(game))
}

func (h *GameHandler) Analyze(c *gin.Context) {
	gameID := c.Param("id")
	game, ok := h.gameService.GetGame(gameID)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
		return
	}
	analysis, err := h.kataGoService.AnalyzePosition(game)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, analysis)
}

type explainRequest struct {
	MoveNumber int    `json:"move_number"`
	Move       string `json:"move"`
	WinRateChange float64 `json:"win_rate_change"`
	Context    string `json:"context"`
}

func (h *GameHandler) ExplainMove(c *gin.Context) {
	var req explainRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	explanation, err := h.kimiService.ExplainMove(req.Move, req.MoveNumber, req.WinRateChange, req.Context)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, explanation)
}

type questionRequest struct {
	GameSGF  string `json:"game_sgf"`
	Question string `json:"question"`
}

func (h *GameHandler) AskQuestion(c *gin.Context) {
	var req questionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	answer, err := h.kimiService.ExplainPosition(req.GameSGF, req.Question)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"answer": answer})
}

func (h *GameHandler) GetSGF(c *gin.Context) {
	gameID := c.Param("id")
	game, ok := h.gameService.GetGame(gameID)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
		return
	}
	sgf := h.gameService.GameToSGF(game)
	c.Header("Content-Type", "application/x-go-sgf")
	c.Header("Content-Disposition", "attachment; filename=game.sgf")
	c.String(http.StatusOK, sgf)
}

type summaryRequest struct {
	SGF    string `json:"sgf"`
	Result string `json:"result"`
}

func (h *GameHandler) GameSummary(c *gin.Context) {
	var req summaryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	summary, err := h.kimiService.AnalyzeGameSummary(req.SGF, req.Result)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"summary": summary})
}
