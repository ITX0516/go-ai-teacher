package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port        int
	KataGoPath  string
	KataGoModel string
	KimiAPIKey  string
	KimiAPIURL  string
}

func Load() *Config {
	port, _ := strconv.Atoi(getEnv("PORT", "8080"))
	return &Config{
		Port:        port,
		KataGoPath:  getEnv("KATAGO_PATH", "./katago/katago"),
		KataGoModel: getEnv("KATAGO_MODEL", "./katago/model.bin.gz"),
		KimiAPIKey:  getEnv("KIMI_API_KEY", ""),
		KimiAPIURL:  getEnv("KIMI_API_URL", "https://api.moonshot.cn/v1/chat/completions"),
	}
}

func getEnv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
