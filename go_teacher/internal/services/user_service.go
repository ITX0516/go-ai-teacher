package services

import (
	"go_teacher/internal/models"
	"sync"
)

type UserService struct {
	mu           sync.RWMutex
	users        map[string]*models.UserProgress
	achievements []Achievement
}

type Achievement struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Icon        string `json:"icon"`
	XP          int    `json:"xp"`
}

func NewUserService() *UserService {
	return &UserService{
		users: make(map[string]*models.UserProgress),
		achievements: getDefaultAchievements(),
	}
}

func (s *UserService) GetProgress(userID string) *models.UserProgress {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if p, ok := s.users[userID]; ok {
		return p
	}
	return nil
}

func (s *UserService) CreateUser(userID string) *models.UserProgress {
	s.mu.Lock()
	defer s.mu.Unlock()
	p := &models.UserProgress{
		UserID:       userID,
		Level:        1,
		XP:           0,
		GamesPlayed:  0,
		GamesWon:     0,
		PuzzlesSolved: 0,
		CurrentStreak: 0,
		LongestStreak: 0,
		Achievements: []string{},
	}
	s.users[userID] = p
	return p
}

func (s *UserService) AddXP(userID string, xp int) *models.UserProgress {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.users[userID]
	if !ok {
		p = s.createUserInternal(userID)
	}
	p.XP += xp
	for p.XP >= xpForLevel(p.Level+1) {
		p.Level++
	}
	return p
}

func (s *UserService) RecordGame(userID string, won bool) *models.UserProgress {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.users[userID]
	if !ok {
		p = s.createUserInternal(userID)
	}
	p.GamesPlayed++
	if won {
		p.GamesWon++
		p.XP += 50
	} else {
		p.XP += 20
	}
	for p.XP >= xpForLevel(p.Level+1) {
		p.Level++
	}
	s.checkAchievements(p)
	return p
}

func (s *UserService) RecordPuzzleSolved(userID string) *models.UserProgress {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.users[userID]
	if !ok {
		p = s.createUserInternal(userID)
	}
	p.PuzzlesSolved++
	p.XP += 15
	for p.XP >= xpForLevel(p.Level+1) {
		p.Level++
	}
	s.checkAchievements(p)
	return p
}

func (s *UserService) RecordLogin(userID string) *models.UserProgress {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.users[userID]
	if !ok {
		p = s.createUserInternal(userID)
	}
	p.CurrentStreak++
	if p.CurrentStreak > p.LongestStreak {
		p.LongestStreak = p.CurrentStreak
	}
	s.checkAchievements(p)
	return p
}

func (s *UserService) createUserInternal(userID string) *models.UserProgress {
	p := &models.UserProgress{
		UserID:       userID,
		Level:        1,
		XP:           0,
		GamesPlayed:  0,
		GamesWon:     0,
		PuzzlesSolved: 0,
		CurrentStreak: 1,
		LongestStreak: 1,
		Achievements: []string{},
	}
	s.users[userID] = p
	return p
}

func (s *UserService) checkAchievements(p *models.UserProgress) {
	hasAchievement := func(id string) bool {
		for _, a := range p.Achievements {
			if a == id {
				return true
			}
		}
		return false
	}

	for _, ach := range s.achievements {
		if hasAchievement(ach.ID) {
			continue
		}
		unlocked := false
		switch ach.ID {
		case "first_game":
			unlocked = p.GamesPlayed >= 1
		case "ten_games":
			unlocked = p.GamesPlayed >= 10
		case "first_win":
			unlocked = p.GamesWon >= 1
		case "first_puzzle":
			unlocked = p.PuzzlesSolved >= 1
		case "puzzle_master":
			unlocked = p.PuzzlesSolved >= 100
		case "streak_3":
			unlocked = p.CurrentStreak >= 3
		case "streak_7":
			unlocked = p.LongestStreak >= 7
		case "level_5":
			unlocked = p.Level >= 5
		case "level_10":
			unlocked = p.Level >= 10
		}
		if unlocked {
			p.Achievements = append(p.Achievements, ach.ID)
			p.XP += ach.XP
		}
	}
}

func (s *UserService) GetAchievements() []Achievement {
	return s.achievements
}

func xpForLevel(level int) int {
	if level <= 1 {
		return 0
	}
	return (level - 1) * 100 * level / 2
}

func getDefaultAchievements() []Achievement {
	return []Achievement{
		{ID: "first_game", Name: "初出茅庐", Description: "完成第一局对弈", Icon: "🎮", XP: 50},
		{ID: "ten_games", Name: "小试牛刀", Description: "完成10局对弈", Icon: "⚔️", XP: 100},
		{ID: "first_win", Name: "旗开得胜", Description: "赢得第一局比赛", Icon: "🏆", XP: 30},
		{ID: "first_puzzle", Name: "初窥门径", Description: "解决第一道死活题", Icon: "🧩", XP: 20},
		{ID: "puzzle_master", Name: "解题达人", Description: "解决100道死活题", Icon: "💡", XP: 200},
		{ID: "streak_3", Name: "坚持不懈", Description: "连续学习3天", Icon: "🔥", XP: 30},
		{ID: "streak_7", Name: "周周精进", Description: "连续学习7天", Icon: "📅", XP: 100},
		{ID: "level_5", Name: "棋艺初成", Description: "达到5级", Icon: "⭐", XP: 100},
		{ID: "level_10", Name: "登堂入室", Description: "达到10级", Icon: "🌟", XP: 300},
	}
}
