package services

import (
	"go_teacher/internal/models"
	"regexp"
)

// 题库索引 JSON 内容
const puzzlesJSONContent = `[
  {"id": "p001", "title": "直三死活", "difficulty": "beginner", "category": "life_death", "description": "黑先，如何做活？", "sgf_path": "data/puzzles/1_直三.sgf"},
  {"id": "p002", "title": "弯三死活", "difficulty": "beginner", "category": "life_death", "description": "黑先，如何做活？", "sgf_path": "data/puzzles/2_弯三.sgf"},
  {"id": "p003", "title": "丁四死活", "difficulty": "beginner", "category": "life_death", "description": "黑先，如何做活？", "sgf_path": "data/puzzles/3_丁四.sgf"},
  {"id": "p004", "title": "倒扑吃子", "difficulty": "beginner", "category": "capture", "description": "黑先，如何吃住白棋？", "sgf_path": "data/puzzles/4_倒扑.sgf"},
  {"id": "p005", "title": "征子练习", "difficulty": "beginner", "category": "capture", "description": "黑先，能否征吃白子？", "sgf_path": "data/puzzles/5_征子.sgf"},
  {"id": "p006", "title": "星位小飞挂", "difficulty": "intermediate", "category": "joseki", "description": "黑星位，白小飞挂，黑如何应对？", "sgf_path": "data/puzzles/6_星位小飞挂.sgf"},
  {"id": "p007", "title": "双吃吃子", "difficulty": "beginner", "category": "capture", "description": "黑先，如何双吃白棋？", "sgf_path": "data/puzzles/7_双吃.sgf"},
  {"id": "p008", "title": "枷吃吃子", "difficulty": "intermediate", "category": "capture", "description": "黑先，如何枷吃白棋？", "sgf_path": "data/puzzles/8_枷吃.sgf"},
  {"id": "p009", "title": "接不归", "difficulty": "intermediate", "category": "capture", "description": "黑先，如何利用接不归吃子？", "sgf_path": "data/puzzles/9_接不归.sgf"},
  {"id": "p010", "title": "立四死活", "difficulty": "beginner", "category": "life_death", "description": "黑先，立四是活形吗？", "sgf_path": "data/puzzles/10_立四.sgf"}
]`

// 预加载的 SGF 内容（内嵌）
var puzzleSGFs = map[string]string{
	"p001": "(;GM[1]SZ[9]KM[6.5]AB[cd][dd][ed][fd][ce][fe][cf][ff]AW[df][ef];B[cf]C[正解！黑棋下在C4位做眼，形成直四活形。要点：直三的要点在中间。])",
	"p002": "(;GM[1]SZ[9]KM[6.5]AB[bc][cc][dc][bd][be]AW[dd][ce][de];B[cd]C[正解！弯三的要点在中间。黑下C6后形成完整眼位。])",
	"p003": "(;GM[1]SZ[9]KM[6.5]AB[cd][dd][ed][ce][de][cf][df]AW[be][bf][ef][ee];B[ee]C[正解！丁四（也称板四、方四）是活形，对方无法杀。])",
	"p004": "(;GM[1]SZ[9]KM[6.5]AB[de][dg][eg]AW[ee][fe][ef][ff];B[ff]C[正解！黑棋F4位倒扑，白棋提子后黑棋可以反提。要点：倒扑是送吃后再吃回的技巧。])",
	"p005": "(;GM[1]SZ[9]KM[6.5]AB[ec][fc]AW[dd][ee];B[ed]C[正解！黑棋E6位开始征子，白棋无法逃脱。要点：征子要看前方是否有接应。])",
	"p006": "(;GM[1]SZ[9]KM[6.5]AB[gg]AW[eg];B[fg]C[正解！黑F4位小飞应是稳健的下法，守住角地同时准备扩张。])",
	"p007": "(;GM[1]SZ[9]KM[6.5]AB[cc][dc][cd]AW[dd][ed][ce];B[de]C[正解！黑D5位双吃，白棋两边无法兼顾，必丢一边。要点：双吃是制造对方两处断点同时打吃的技巧。])",
	"p008": "(;GM[1]SZ[9]KM[6.5]AB[cc][dc][ec][dd][de]AW[cd][ce][cf][df];B[ee]C[正解！黑E5位枷吃，白棋无法逃出。枷吃像笼子一样罩住对方，是常用的吃子技巧。])",
	"p009": "(;GM[1]SZ[9]KM[6.5]AB[cc][dc][cd][dd][de]AW[bd][be][ce][cf][df][ee];B[ed]C[正解！黑E6位打吃，白棋无法接上（接不归）。要点：利用对方棋形缺陷，使其无法连回。])",
	"p010": "(;GM[1]SZ[9]KM[6.5]AB[cc][dc][ec][fc][cd][ce][cf]AW[bc][bd][be][bf][cg][dg][eg][fg][bg];B[df]C[正解！立四是活形，黑棋已经确保两只眼。立四的眼位充足，对方无法杀。])",
}

type puzzleIndex struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Difficulty  string `json:"difficulty"`
	Category    string `json:"category"`
	Description string `json:"description"`
	SGFPath     string `json:"sgf_path"`
}

type PuzzleService struct {
	puzzles []models.Puzzle
}

func NewPuzzleService() *PuzzleService {
	return &PuzzleService{
		puzzles: loadPuzzlesFromSGF(),
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
	for i := range s.puzzles {
		if s.puzzles[i].ID == id {
			return &s.puzzles[i], true
		}
	}
	return nil, false
}

func loadPuzzlesFromSGF() []models.Puzzle {
	// 直接从内嵌 map 加载
	result := make([]models.Puzzle, 0, len(puzzleSGFs))

	// 预定义索引信息
	indexes := []puzzleIndex{
		{ID: "p001", Title: "直三死活", Difficulty: "beginner", Category: "life_death", Description: "黑先，如何做活？"},
		{ID: "p002", Title: "弯三死活", Difficulty: "beginner", Category: "life_death", Description: "黑先，如何做活？"},
		{ID: "p003", Title: "丁四死活", Difficulty: "beginner", Category: "life_death", Description: "黑先，如何做活？"},
		{ID: "p004", Title: "倒扑吃子", Difficulty: "beginner", Category: "capture", Description: "黑先，如何吃住白棋？"},
		{ID: "p005", Title: "征子练习", Difficulty: "beginner", Category: "capture", Description: "黑先，能否征吃白子？"},
		{ID: "p006", Title: "星位小飞挂", Difficulty: "intermediate", Category: "joseki", Description: "黑星位，白小飞挂，黑如何应对？"},
		{ID: "p007", Title: "双吃吃子", Difficulty: "beginner", Category: "capture", Description: "黑先，如何双吃白棋？"},
		{ID: "p008", Title: "枷吃吃子", Difficulty: "intermediate", Category: "capture", Description: "黑先，如何枷吃白棋？"},
		{ID: "p009", Title: "接不归", Difficulty: "intermediate", Category: "capture", Description: "黑先，如何利用接不归吃子？"},
		{ID: "p010", Title: "立四死活", Difficulty: "beginner", Category: "life_death", Description: "黑先，立四是活形吗？"},
	}

	for _, idx := range indexes {
		sgf, ok := puzzleSGFs[idx.ID]
		if !ok {
			continue
		}
		puzzle, err := parsePuzzleSGF(idx.ID, idx.Title, idx.Difficulty, idx.Category, idx.Description, sgf)
		if err != nil {
			continue
		}
		result = append(result, *puzzle)
	}
	return result
}

// parsePuzzleSGF 解析死活题 SGF，提取 AB/AW（初始摆子）和正解（B 的第一步）
func parsePuzzleSGF(id, title, difficulty, category, description, sgf string) (*models.Puzzle, error) {
	initialStones := make([]models.Move, 0)

	// 解析 AB（黑子初始摆子）
	abRegex := regexp.MustCompile(`AB((?:\[[a-s]{2}\])+)`)
	if abMatch := abRegex.FindStringSubmatch(sgf); len(abMatch) > 1 {
		coords := extractCoords(abMatch[1])
		for _, c := range coords {
			x, y := sgfCoordToXY(c)
			initialStones = append(initialStones, models.Move{X: x, Y: y, Color: models.Black, Move: coordToGTP(x, y, 9)})
		}
	}

	// 解析 AW（白子初始摆子）
	awRegex := regexp.MustCompile(`AW((?:\[[a-s]{2}\])+)`)
	if awMatch := awRegex.FindStringSubmatch(sgf); len(awMatch) > 1 {
		coords := extractCoords(awMatch[1])
		for _, c := range coords {
			x, y := sgfCoordToXY(c)
			initialStones = append(initialStones, models.Move{X: x, Y: y, Color: models.White, Move: coordToGTP(x, y, 9)})
		}
	}

	// 解析正解：第一个 ;B[xx]
	var correctMoves []string
	solRegex := regexp.MustCompile(`;B\[([a-s]{2})\]`)
	if solMatch := solRegex.FindStringSubmatch(sgf); len(solMatch) > 1 {
		x, y := sgfCoordToXY(solMatch[1])
		correctMoves = append(correctMoves, coordToGTP(x, y, 9))
	}

	// 提取注释作为 solution
	solution := ""
	cRegex := regexp.MustCompile(`C\[([^\]]+)\]`)
	if cMatch := cRegex.FindStringSubmatch(sgf); len(cMatch) > 1 {
		solution = cMatch[1]
	}

	return &models.Puzzle{
		ID:            id,
		Title:         title,
		Difficulty:    difficulty,
		Category:      category,
		Description:   description,
		BoardSize:     9,
		InitialStones: initialStones,
		CorrectMoves:  correctMoves,
		Solution:      solution,
	}, nil
}

func extractCoords(s string) []string {
	var coords []string
	re := regexp.MustCompile(`\[([a-s]{2})\]`)
	matches := re.FindAllStringSubmatch(s, -1)
	for _, m := range matches {
		if len(m) > 1 {
			coords = append(coords, m[1])
		}
	}
	return coords
}

func sgfCoordToXY(coord string) (int, int) {
	if len(coord) < 2 {
		return -1, -1
	}
	x := int(coord[0] - 'a')
	y := int(coord[1] - 'a')
	return x, y
}

