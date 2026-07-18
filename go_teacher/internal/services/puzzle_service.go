package services

import (
	"go_teacher/internal/models"
)

type PuzzleService struct {
	puzzles []models.Puzzle
}

func NewPuzzleService() *PuzzleService {
	return &PuzzleService{
		puzzles: getDefaultPuzzles(),
	}
}

func (s *PuzzleService) GetPuzzles(category, difficulty string) []models.Puzzle {
	result := make([]models.Puzzle, 0)
	for _, p := range s.puzzles {
		if category != "" && p.Category != category {
			continue
		}
		if difficulty != "" && p.Difficulty != difficulty {
			continue
		}
		result = append(result, p)
	}
	return result
}

func (s *PuzzleService) GetPuzzle(id string) (*models.Puzzle, bool) {
	for _, p := range s.puzzles {
		if p.ID == id {
			return &p, true
		}
	}
	return nil, false
}

func getDefaultPuzzles() []models.Puzzle {
	return []models.Puzzle{
		{
			ID:          "p001",
			Title:       "直三死活",
			Difficulty:  "beginner",
			Category:    "life_death",
			Description: "黑先，如何做活？",
			BoardSize:   9,
			InitialStones: []models.Move{
				{X: 2, Y: 3, Color: 1, Move: "C6"},
				{X: 3, Y: 3, Color: 1, Move: "D6"},
				{X: 4, Y: 3, Color: 1, Move: "E6"},
				{X: 5, Y: 3, Color: 1, Move: "F6"},
				{X: 2, Y: 4, Color: 1, Move: "C5"},
				{X: 5, Y: 4, Color: 1, Move: "F5"},
				{X: 2, Y: 5, Color: 1, Move: "C4"},
				{X: 3, Y: 5, Color: 2, Move: "D4"},
				{X: 4, Y: 5, Color: 2, Move: "E4"},
				{X: 5, Y: 5, Color: 1, Move: "F4"},
			},
			CorrectMoves: []string{"C4"},
			Solution:    "黑棋下在C4位做眼，形成直四活形。要点：直三的要点在中间。",
		},
		{
			ID:          "p002",
			Title:       "方四死活",
			Difficulty:  "beginner",
			Category:    "life_death",
			Description: "黑先，如何做活？",
			BoardSize:   9,
			InitialStones: []models.Move{
				{X: 1, Y: 2, Color: 1, Move: "B7"},
				{X: 2, Y: 2, Color: 1, Move: "C7"},
				{X: 3, Y: 2, Color: 1, Move: "D7"},
				{X: 1, Y: 3, Color: 1, Move: "B6"},
				{X: 3, Y: 3, Color: 2, Move: "D6"},
				{X: 1, Y: 4, Color: 1, Move: "B5"},
				{X: 2, Y: 4, Color: 2, Move: "C5"},
				{X: 3, Y: 4, Color: 2, Move: "D5"},
			},
			CorrectMoves: []string{"C6"},
			Solution:    "方四的死活要点在C6位。要点：方四是死形，但如果对方不补，可以点死。",
		},
		{
			ID:          "p003",
			Title:       "倒扑吃子",
			Difficulty:  "beginner",
			Category:    "capture",
			Description: "黑先，如何吃住白棋？",
			BoardSize:   9,
			InitialStones: []models.Move{
				{X: 3, Y: 4, Color: 1, Move: "D5"},
				{X: 4, Y: 4, Color: 2, Move: "E5"},
				{X: 5, Y: 4, Color: 2, Move: "F5"},
				{X: 4, Y: 5, Color: 2, Move: "E4"},
				{X: 3, Y: 6, Color: 1, Move: "D3"},
				{X: 4, Y: 6, Color: 1, Move: "E3"},
			},
			CorrectMoves: []string{"F4"},
			Solution:    "黑棋F4位倒扑，白棋提子后黑棋可以反提。要点：倒扑是送吃后再吃回的技巧。",
		},
		{
			ID:          "p004",
			Title:       "征子练习",
			Difficulty:  "beginner",
			Category:    "capture",
			Description: "黑先，能否征吃白子？",
			BoardSize:   9,
			InitialStones: []models.Move{
				{X: 4, Y: 2, Color: 1, Move: "E7"},
				{X: 3, Y: 3, Color: 2, Move: "D6"},
				{X: 5, Y: 3, Color: 1, Move: "F6"},
				{X: 4, Y: 4, Color: 2, Move: "E5"},
			},
			CorrectMoves: []string{"E6"},
			Solution:    "黑棋E6位开始征子，白棋无法逃脱。要点：征子要看前方是否有接应。",
		},
		{
			ID:          "p005",
			Title:       "基础定式-星位小飞挂",
			Difficulty:  "intermediate",
			Category:    "joseki",
			Description: "黑星位，白小飞挂，黑如何应对？",
			BoardSize:   9,
			InitialStones: []models.Move{
				{X: 6, Y: 6, Color: 1, Move: "G3"},
				{X: 4, Y: 5, Color: 2, Move: "E4"},
			},
			CorrectMoves: []string{"F4", "G4", "F2"},
			Solution:    "常见应对有小飞应(F4)、大飞应、尖顶(G4)、靠压等。小飞应是最稳健的下法。",
		},
	}
}
