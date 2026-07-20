package config

import (
	"os"
	"strconv"
)

// KataGoConfig KataGo 引擎配置
type KataGoConfig struct {
	ExecutablePath      string // 可执行文件路径
	ModelPath           string // 权重文件路径
	ConfigPath          string // GTP 配置文件路径
	MaxVisits           int    // 最大访问次数
	NumAnalysisThreads  int    // 分析线程数
	NNMaxBatchSize      int    // 神经网络批处理大小
}

type Config struct {
	Port            int
	KataGo          KataGoConfig
	DeepSeekAPIKey  string
	DeepSeekAPIURL  string
}

func Load() *Config {
	port, _ := strconv.Atoi(getEnv("PORT", "8080"))
	maxVisits, _ := strconv.Atoi(getEnv("KATAGO_MAX_VISITS", "20"))
	numThreads, _ := strconv.Atoi(getEnv("KATAGO_THREADS", "2"))
	batchSize, _ := strconv.Atoi(getEnv("KATAGO_BATCH_SIZE", "2"))
	return &Config{
		Port: port,
		KataGo: KataGoConfig{
			ExecutablePath:      getEnv("KATAGO_EXE", "C:\\Katago\\katago.exe"),
			ModelPath:           getEnv("KATAGO_MODEL", "C:\\Katago\\networks\\kata1-b6c96-s175395328-d26788732.txt.gz"),
			ConfigPath:          getEnv("KATAGO_CONFIG", "C:\\Katago\\default_gtp.cfg"),
			MaxVisits:           maxVisits,
			NumAnalysisThreads:  numThreads,
			NNMaxBatchSize:      batchSize,
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
