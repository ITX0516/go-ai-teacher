package services

import (
	"encoding/json"
	"fmt"
	"go_teacher/internal/models"
)

type GameService struct {
	games map[string]*models.GameState
}

func NewGameService() *GameService {
	return &GameService{
		games: make(map[string]*models.GameState),
	}
}

func (s *GameService) NewGame(gameID string, size int, komi float64) *models.GameState {
	game := models.NewGame(size, komi)
	s.games[gameID] = game
	return game
}

func (s *GameService) GetGame(gameID string) (*models.GameState, bool) {
	game, ok := s.games[gameID]
	return game, ok
}

func (s *GameService) PlayMove(gameID string, x, y int, color models.Stone) (*models.GameState, error) {
	game, ok := s.games[gameID]
	if !ok {
		return nil, fmt.Errorf("game not found")
	}
	if game.Current != color {
		return nil, fmt.Errorf("not your turn")
	}
	if !game.PlayMove(x, y, color) {
		return nil, fmt.Errorf("invalid move")
	}
	return game, nil
}

func (s *GameService) UndoMove(gameID string) (*models.GameState, error) {
	game, ok := s.games[gameID]
	if !ok {
		return nil, fmt.Errorf("game not found")
	}
	if len(game.Moves) == 0 {
		return nil, fmt.Errorf("no moves to undo")
	}
	lastMoveCount := len(game.Moves)
	if lastMoveCount >= 2 {
		game.Moves = game.Moves[:lastMoveCount-2]
	} else {
		game.Moves = game.Moves[:lastMoveCount-1]
	}
	game = s.replayMoves(game)
	s.games[gameID] = game
	return game, nil
}

func (s *GameService) replayMoves(game *models.GameState) *models.GameState {
	moves := game.Moves
	newGame := models.NewGame(game.BoardSize, game.Komi)
	for _, move := range moves {
		newGame.PlayMove(move.X, move.Y, move.Color)
	}
	return newGame
}

func (s *GameService) GameToSGF(game *models.GameState) string {
	sgf := fmt.Sprintf("(;GM[1]SZ[%d]KM[%.1f]", game.BoardSize, game.Komi)
	for i, move := range game.Moves {
		color := "B"
		if move.Color == models.White {
			color = "W"
		}
		sgf += fmt.Sprintf(";%s[%s]", color, moveToSGF(move.X, move.Y, game.BoardSize))
		_ = i
	}
	sgf += ")"
	return sgf
}

// sgfLetters sgf 字母表（OGS / SGF FF4 标准）：a..s 不跳 i，共 19 个字母
var sgfLetters = []rune{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's'}

// moveToSGF 将棋盘坐标 (x, y) 转为 SGF 坐标字符串
// 棋盘 x 是列（0=left=A），y 是行（0=顶行=围棋行 1 from 顶）
// 围棋行号 1-based from 底 = boardSize - y
// sgf 字母表 a..s 不跳 i，索引 0..18
// 围棋列 A..T 跳 I：J..T 跳过 sgf 的 'i'，列索引 +1
//   例外：T 列（索引 18）→ sgf 索引 18='s'（不 +1）
func moveToSGF(x, y, size int) string {
	if x < 0 || y < 0 {
		return "tt"
	}
	sgfCol := x
	if x >= 8 && x < 18 {
		sgfCol++ // 跳 sgf 'i'
	}
	if sgfCol >= len(sgfLetters) {
		sgfCol = len(sgfLetters) - 1
	}
	sgfRowIdx := y
	return string([]rune{sgfLetters[sgfCol], sgfLetters[sgfRowIdx]})
}

type JSONGameState struct {
	BoardSize int        `json:"board_size"`
	Board     [][]int    `json:"board"`
	Moves     []models.Move `json:"moves"`
	Komi      float64    `json:"komi"`
	Current   int        `json:"current"`
	Result    string     `json:"result,omitempty"`
}

func GameStateToJSON(g *models.GameState) JSONGameState {
	intBoard := make([][]int, g.BoardSize)
	for y := 0; y < g.BoardSize; y++ {
		intBoard[y] = make([]int, g.BoardSize)
		for x := 0; x < g.BoardSize; x++ {
			intBoard[y][x] = int(g.Board[y][x])
		}
	}
	return JSONGameState{
		BoardSize: g.BoardSize,
		Board:     intBoard,
		Moves:     g.Moves,
		Komi:      g.Komi,
		Current:   int(g.Current),
		Result:    g.Result,
	}
}

func GameStateBytes(g *models.GameState) []byte {
	j := GameStateToJSON(g)
	b, _ := json.Marshal(j)
	return b
}
