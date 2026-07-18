package handlers

import (
	"go_teacher/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type PuzzleHandler struct {
	puzzleService *services.PuzzleService
	kimiService   *services.KimiService
}

func NewPuzzleHandler(ps *services.PuzzleService, ks *services.KimiService) *PuzzleHandler {
	return &PuzzleHandler{
		puzzleService: ps,
		kimiService:   ks,
	}
}

func (h *PuzzleHandler) ListPuzzles(c *gin.Context) {
	category := c.Query("category")
	difficulty := c.Query("difficulty")
	puzzles := h.puzzleService.GetPuzzles(category, difficulty)
	c.JSON(http.StatusOK, gin.H{"puzzles": puzzles})
}

func (h *PuzzleHandler) GetPuzzle(c *gin.Context) {
	id := c.Param("id")
	puzzle, ok := h.puzzleService.GetPuzzle(id)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "puzzle not found"})
		return
	}
	c.JSON(http.StatusOK, puzzle)
}

type checkAnswerRequest struct {
	Move string `json:"move"`
}

func (h *PuzzleHandler) CheckAnswer(c *gin.Context) {
	id := c.Param("id")
	var req checkAnswerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	puzzle, ok := h.puzzleService.GetPuzzle(id)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "puzzle not found"})
		return
	}
	isCorrect := false
	for _, correct := range puzzle.CorrectMoves {
		if correct == req.Move {
			isCorrect = true
			break
		}
	}
	explanation, _ := h.kimiService.GeneratePuzzleExplanation(puzzle, isCorrect, req.Move)
	c.JSON(http.StatusOK, gin.H{
		"correct":     isCorrect,
		"explanation": explanation,
		"solution":    puzzle.Solution,
	})
}
