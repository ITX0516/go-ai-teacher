package main

import (
	"fmt"
	"go_teacher/internal/config"
	"go_teacher/internal/handlers"
	"go_teacher/internal/services"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()

	cfg := config.Load()

	gameService := services.NewGameService()
	kataGoService := services.NewKataGoService(cfg.KataGo)
	defer kataGoService.Close()
	deepseekService := services.NewDeepSeekService(cfg.DeepSeekAPIKey, cfg.DeepSeekAPIURL)
	puzzleService := services.NewPuzzleService()
	userService := services.NewUserService()

	gameHandler := handlers.NewGameHandler(gameService, kataGoService, deepseekService)
	puzzleHandler := handlers.NewPuzzleHandler(puzzleService, deepseekService)
	userHandler := handlers.NewUserHandler(userService)

	r := gin.Default()

	r.Use(cors.New(cors.Config{
		AllowAllOrigins:  true,
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		AllowCredentials: true,
	}))

	api := r.Group("/api")
	{
		games := api.Group("/games")
		{
			games.POST("/:id", gameHandler.NewGame)
			games.GET("/:id", gameHandler.GetGame)
			games.POST("/:id/move", gameHandler.PlayMove)
			games.POST("/:id/ai-move", gameHandler.AIMove)
			games.POST("/:id/undo", gameHandler.UndoMove)
			games.GET("/:id/analyze", gameHandler.Analyze)
			games.GET("/:id/sgf", gameHandler.GetSGF)
			games.POST("/:id/explain", gameHandler.ExplainMove)
			games.POST("/:id/ask", gameHandler.AskQuestion)
			games.POST("/summary", gameHandler.GameSummary)
		}

		// KataGo 直连接口
		game := api.Group("/game")
		{
			game.POST("/analyze", gameHandler.AnalyzeSGF)
			game.POST("/ai-move", gameHandler.AIGenMove)
		}

		puzzles := api.Group("/puzzles")
		{
			puzzles.GET("", puzzleHandler.ListPuzzles)
			puzzles.GET("/:id", puzzleHandler.GetPuzzle)
			puzzles.POST("/:id/check", puzzleHandler.CheckAnswer)
		}

		users := api.Group("/users")
		{
			users.GET("/:id/progress", userHandler.GetProgress)
			users.POST("/:id/login", userHandler.Login)
			users.POST("/:id/game", userHandler.RecordGame)
			users.POST("/:id/puzzle", userHandler.RecordPuzzle)
		}

		api.GET("/achievements", userHandler.ListAchievements)

		api.GET("/health", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"status":  "ok",
				"service": "Go Teacher API",
				"version": "1.0.0",
			})
		})
	}

	// 优雅退出：捕获 SIGINT/SIGTERM，让 defer kataGoService.Close() 生效
	go func() {
		sigCh := make(chan os.Signal, 1)
		signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
		<-sigCh
		log.Println("收到退出信号，正在关闭服务...")
		os.Exit(0)
	}()

	log.Printf("Server starting on port %d...", cfg.Port)
	if err := r.Run(fmt.Sprintf(":%d", cfg.Port)); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
