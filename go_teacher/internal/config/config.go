package config

import (
	"os"
	"strconv"
)

// KataGoConfig KataGo 引擎配置
type KataGoConfig struct {
	ExecutablePath string // 可执行文件路径
	ModelPath      string // 权重文件路径
	ConfigPath     string // GTP 配置文件路径
}

type Config struct {
	Port            int
	KataGo          KataGoConfig
	DeepSeekAPIKey  string
	DeepSeekAPIURL  string
}

func Load() *Config {
	port, _ := strconv.Atoi(getEnv("PORT", "8080"))
	return &Config{
		Port: port,
		KataGo: KataGoConfig{
			ExecutablePath: getEnv("KATAGO_EXE", "C:\\Katago\\katago.exe"),
			ModelPath:      getEnv("KATAGO_MODEL", "C:\\Katago\\networks\\kata1-b15c192-s1672170752-d466197061.txt.gz"),
			ConfigPath:     getEnv("KATAGO_CONFIG", "C:\\Katago\\default_gtp.cfg"),
		},
		DeepSeekAPIKey: getEnv("DEEPSEEK_API_KEY", ""),
		DeepSeekAPIURL: getEnv("DEEPSEEK_API_URL", "https://api.deepseek.com/chat/completions"),
	}
}

func getEnv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
