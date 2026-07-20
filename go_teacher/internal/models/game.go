package models

type Stone int

const (
	Empty Stone = iota
	Black
	White
)

type Move struct {
	X     int    `json:"x"`
	Y     int    `json:"y"`
	Color Stone  `json:"color"`
	Move  string `json:"move"`
}

type GameState struct {
	BoardSize int     `json:"board_size"`
	Board     [][]Stone `json:"board"`
	Moves     []Move  `json:"moves"`
	Komi      float64 `json:"komi"`
	Current   Stone   `json:"current"`
	Result    string  `json:"result,omitempty"`
}

func NewGame(size int, komi float64) *GameState {
	board := make([][]Stone, size)
	for i := range board {
		board[i] = make([]Stone, size)
	}
	return &GameState{
		BoardSize: size,
		Board:     board,
		Komi:      komi,
		Current:   Black,
		Moves:     make([]Move, 0),
	}
}

func (g *GameState) PlayMove(x, y int, color Stone) bool {
	if x == -1 && y == -1 {
		g.Moves = append(g.Moves, Move{
			X:     -1,
			Y:     -1,
			Color: color,
			Move:  "pass",
		})
		g.Current = 3 - color
		return true
	}
	if x < 0 || x >= g.BoardSize || y < 0 || y >= g.BoardSize {
		return false
	}
	if g.Board[y][x] != Empty {
		return false
	}
	g.Board[y][x] = color
	g.removeCaptured(x, y, color)
	g.Moves = append(g.Moves, Move{
		X:     x,
		Y:     y,
		Color: color,
		Move:  coordToMove(x, y, g.BoardSize),
	})
	g.Current = 3 - color
	return true
}

func (g *GameState) removeCaptured(x, y int, color Stone) {
	opponent := 3 - color
	dx := []int{-1, 1, 0, 0}
	dy := []int{0, 0, -1, 1}
	for i := 0; i < 4; i++ {
		nx, ny := x+dx[i], y+dy[i]
		if nx >= 0 && nx < g.BoardSize && ny >= 0 && ny < g.BoardSize {
			if g.Board[ny][nx] == opponent {
				if g.countLiberties(nx, ny) == 0 {
					g.removeGroup(nx, ny)
				}
			}
		}
	}
}

func (g *GameState) countLiberties(x, y int) int {
	color := g.Board[y][x]
	if color == Empty {
		return 0
	}
	visited := make(map[[2]int]bool)
	return g.countLibertiesDFS(x, y, color, visited)
}

func (g *GameState) countLibertiesDFS(x, y int, color Stone, visited map[[2]int]bool) int {
	key := [2]int{x, y}
	if visited[key] {
		return 0
	}
	if x < 0 || x >= g.BoardSize || y < 0 || y >= g.BoardSize {
		return 0
	}
	if g.Board[y][x] == Empty {
		visited[key] = true
		return 1
	}
	if g.Board[y][x] != color {
		return 0
	}
	visited[key] = true
	dx := []int{-1, 1, 0, 0}
	dy := []int{0, 0, -1, 1}
	count := 0
	for i := 0; i < 4; i++ {
		count += g.countLibertiesDFS(x+dx[i], y+dy[i], color, visited)
	}
	return count
}

func (g *GameState) removeGroup(x, y int) {
	color := g.Board[y][x]
	if color == Empty {
		return
	}
	g.Board[y][x] = Empty
	dx := []int{-1, 1, 0, 0}
	dy := []int{0, 0, -1, 1}
	for i := 0; i < 4; i++ {
		nx, ny := x+dx[i], y+dy[i]
		if nx >= 0 && nx < g.BoardSize && ny >= 0 && ny < g.BoardSize {
			if g.Board[ny][nx] == color {
				g.removeGroup(nx, ny)
			}
		}
	}
}

func coordToMove(x, y, size int) string {
	letter := rune('A' + x)
	if letter >= 'I' {
		letter++
	}
	return string(letter) + itoa(size-y)
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	result := ""
	for n > 0 {
		result = string(rune('0'+n%10)) + result
		n /= 10
	}
	return result
}

type AnalysisResult struct {
	WinRate    float64   `json:"win_rate"`
	ScoreLead  float64   `json:"score_lead"`
	TopMoves   []TopMove `json:"top_moves"`
	MoveNumber int       `json:"move_number"`
}

type TopMove struct {
	Move        string  `json:"move"`
	WinRate     float64 `json:"win_rate"`
	ScoreLead   float64 `json:"score_lead"`
	Visits      int     `json:"visits"`
	Policy      float64 `json:"policy"`
}

type Explanation struct {
	Move       string `json:"move"`
	Explanation string `json:"explanation"`
	Level      string `json:"level"`
	Tips       string `json:"tips,omitempty"`
}

type Puzzle struct {
	ID          string   `json:"id"`
	Title       string   `json:"title"`
	Difficulty  string   `json:"difficulty"`
	Category    string   `json:"category"`
	Description string   `json:"description"`
	BoardSize   int      `json:"board_size"`
	InitialStones []Move `json:"initial_stones"`
	CorrectMoves []string `json:"correct_moves"`
	Solution    string   `json:"solution"`
}

type UserProgress struct {
	UserID       string  `json:"user_id"`
	Level        int     `json:"level"`
	XP           int     `json:"xp"`
	GamesPlayed  int     `json:"games_played"`
	GamesWon     int     `json:"games_won"`
	PuzzlesSolved int    `json:"puzzles_solved"`
	CurrentStreak int    `json:"current_streak"`
	LongestStreak int    `json:"longest_streak"`
	Achievements []string `json:"achievements"`
}
