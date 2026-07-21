package handlers

import (
	"fmt"
	"go_teacher/internal/models"
	"go_teacher/internal/services"
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

type GameHandler struct {
	gameService     *services.GameService
	kataGoService   *services.KataGoService
	deepseekService *services.DeepSeekService
}

func NewGameHandler(gs *services.GameService, ks *services.KataGoService, deepseek *services.DeepSeekService) *GameHandler {
	return &GameHandler{
		gameService:   gs,
		kataGoService: ks,
		deepseekService:   deepseek,
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
	analysis, _ := h.kataGoService.Analyze(gameMovesToInputs(game), game.BoardSize, int(color))
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
	stoneColor := models.Black
	if req.Color == 2 {
		stoneColor = models.White
	}

	analysis, err := h.kataGoService.Analyze(gameMovesToInputs(game), game.BoardSize, req.Color)
	if err != nil {
		log.Printf("[AI] 分析失败: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	log.Printf("[AI] 候选着法数量: %d, 最佳: %s", len(analysis.CandidateMoves), analysis.BestMove)

	var finalMove string
	var finalX, finalY int
	played := false

	for i, cm := range analysis.CandidateMoves {
		if cm.Move == "pass" || cm.Move == "" {
			continue
		}
		x, y, coordErr := gtpToCoord(cm.Move, game.BoardSize)
		if coordErr != nil {
			log.Printf("[AI] 候选点 %d 坐标解析失败 %s: %v", i, cm.Move, coordErr)
			continue
		}
		_, playErr := h.gameService.PlayMove(gameID, x, y, stoneColor)
		if playErr != nil {
			log.Printf("[AI] 候选点 %d %s 落子失败: %v", i, cm.Move, playErr)
			continue
		}
		finalMove = cm.Move
		finalX = x
		finalY = y
		played = true
		log.Printf("[AI] 使用候选点 %d: %s", i, cm.Move)
		break
	}

	if !played {
		log.Printf("[AI] 所有候选点都失败，执行 pass")
		_, playErr := h.gameService.PlayMove(gameID, -1, -1, stoneColor)
		if playErr != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": playErr.Error()})
			return
		}
		finalMove = "pass"
		finalX = -1
		finalY = -1
	}

	updatedGame, _ := h.gameService.GetGame(gameID)
	c.JSON(http.StatusOK, gin.H{
		"move": finalMove,
		"x":    finalX,
		"y":    finalY,
		"game": services.GameStateToJSON(updatedGame),
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
	analysis, _ := h.kataGoService.Analyze(gameMovesToInputs(game), game.BoardSize, int(game.Current))
	c.JSON(http.StatusOK, analysis)
}

type explainRequest struct {
	SGF           string  `json:"sgf"`
	MoveNumber    int     `json:"move_number"`
	Move          string  `json:"move"`
	WinRateChange float64 `json:"win_rate_change"`
	WinRate       float64 `json:"win_rate"`
	ScoreLead     float64 `json:"score_lead"`
	CurrentTurn   string  `json:"current_turn"`
	Areas         []struct {
		Location string `json:"location"`
		Desc     string `json:"desc"`
	} `json:"areas,omitempty"`
}

func (h *GameHandler) ExplainMove(c *gin.Context) {
	var req explainRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 如果没传 SGF，尝试从 gameID 生成
	if req.SGF == "" {
		gameID := c.Param("id")
		if game, ok := h.gameService.GetGame(gameID); ok {
			req.SGF = h.gameService.GameToSGF(game)
		}
	}

	analysis := &services.MoveAnalysisData{
		WinRate:       req.WinRate,
		ScoreLead:     req.ScoreLead,
		WinRateChange: req.WinRateChange,
		MoveNumber:    req.MoveNumber,
		CurrentTurn:   req.CurrentTurn,
	}

	areas := make([]services.AreaDescription, 0, len(req.Areas))
	for _, a := range req.Areas {
		areas = append(areas, services.AreaDescription{Location: a.Location, Desc: a.Desc})
	}

	explanation, err := h.deepseekService.ExplainMove(req.Move, req.MoveNumber, req.WinRateChange, req.SGF, analysis, areas)
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
	answer, err := h.deepseekService.ExplainPosition(req.GameSGF, req.Question)
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
	summary, err := h.deepseekService.AnalyzeGameSummary(req.SGF, req.Result)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"summary": summary})
}

// ===== 新增 KataGo 直连接口 =====

type analyzeRequest struct {
	Moves     []services.MoveInput `json:"moves"`
	BoardSize int                  `json:"board_size"`
	Color     int                  `json:"color"` // 1=黑, 2=白
}

func (h *GameHandler) AnalyzeSGF(c *gin.Context) {
	var req analyzeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.BoardSize == 0 {
		req.BoardSize = 19
	}
	if req.Color == 0 {
		req.Color = 1
	}

	result, err := h.kataGoService.Analyze(req.Moves, req.BoardSize, req.Color)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

type aiMoveBySGFRequest struct {
	Moves     []services.MoveInput `json:"moves"`
	BoardSize int                  `json:"board_size"`
	Color     int                  `json:"color"` // 1=黑, 2=白
}

func (h *GameHandler) AIGenMove(c *gin.Context) {
	var req aiMoveBySGFRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.BoardSize == 0 {
		req.BoardSize = 19
	}
	if req.Color == 0 {
		req.Color = 2
	}

	move, err := h.kataGoService.GenMove(req.Moves, req.BoardSize, req.Color)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	x, y, _ := gtpToCoord(move, req.BoardSize)

	c.JSON(http.StatusOK, gin.H{
		"move": move,
		"x":    x,
		"y":    y,
	})
}

func gameMovesToInputs(game *models.GameState) []services.MoveInput {
	if game == nil || len(game.Moves) == 0 {
		return []services.MoveInput{}
	}
	inputs := make([]services.MoveInput, len(game.Moves))
	for i, m := range game.Moves {
		color := 1
		if int(m.Color) == 2 {
			color = 2
		}
		inputs[i] = services.MoveInput{
			X:     m.X,
			Y:     m.Y,
			Color: color,
			Move:  coordToGTP(m.X, m.Y, game.BoardSize),
		}
	}
	return inputs
}

func coordToGTP(x, y, boardSize int) string {
	letters := "ABCDEFGHJKLMNOPQRST"
	if x < 0 || x >= len(letters) {
		return "pass"
	}
	gtpY := boardSize - y
	return fmt.Sprintf("%c%d", letters[x], gtpY)
}

// 辅助函数：GTP坐标转x,y
func gtpToCoord(move string, boardSize int) (int, int, error) {
	if move == "pass" || move == "" {
		return -1, -1, nil
	}
	letters := "ABCDEFGHJKLMNOPQRST"
	x := -1
	first := strings.ToUpper(string(move[0]))[0]
	for i, c := range letters {
		if c == rune(first) {
			x = i
			break
		}
	}
	if x == -1 {
		return -1, -1, fmt.Errorf("invalid move: %s", move)
	}
	var y int
	_, err := fmt.Sscanf(move[1:], "%d", &y)
	if err != nil {
		return -1, -1, err
	}
	// GTP y 是从底部开始的 1-based，转成从顶部开始的 0-based
	y = boardSize - y
	return x, y, nil
}
