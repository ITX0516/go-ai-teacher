package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port           int
	DeepSeekAPIKey string
	DeepSeekAPIURL string
	KataGo         KataGoConfig
}

type KataGoConfig struct {
	ExecutablePath     string
	ModelPath          string
	ConfigPath         string
	MaxVisits          int
	NumAnalysisThreads int
	NNMaxBatchSize     int
}

func Load() Config {
	return Config{
		Port:           getEnvInt("PORT", 8080),
		DeepSeekAPIKey: os.Getenv("DEEPSEEK_API_KEY"),
		DeepSeekAPIURL: getEnvDefault("DEEPSEEK_API_URL", "https://api.deepseek.com/v1/chat/completions"),
		KataGo: KataGoConfig{
			ExecutablePath:     getEnvDefault("KATAGO_EXE", "C:\\Katago\\katago.exe"),
			ModelPath:          getEnvDefault("KATAGO_MODEL", "C:\\Katago\\networks\\kata1-b6c96-s175395328-d26788732.txt.gz"),
			ConfigPath:         getEnvDefault("KATAGO_CONFIG", "C:\\Katago\\default_gtp.cfg"),
			MaxVisits:          getEnvInt("KATAGO_MAX_VISITS", 20),
			NumAnalysisThreads: getEnvInt("KATAGO_NUM_THREADS", 2),
			NNMaxBatchSize:     getEnvInt("KATAGO_BATCH_SIZE", 2),
		},
	}
}

func getEnvDefault(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}

func getEnvInt(key string, defaultVal int) int {
	if v := os.Getenv(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return defaultVal
}
