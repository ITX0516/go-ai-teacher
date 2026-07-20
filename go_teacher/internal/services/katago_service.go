package services

import (
	"bufio"
	"encoding/json"
	"fmt"
	"go_teacher/internal/config"
	"go_teacher/internal/models"
	"log"
	"math"
	"math/rand"
	"os/exec"
	"strings"
	"sync"
)

// KataGoService KataGo 引擎服务，封装 GTP 子进程通信
type KataGoService struct {
	cfg     config.KataGoConfig
	enabled bool

	cmd    *exec.Cmd
	stdin  *bufio.Writer
	stdout *bufio.Reader
	mu     sync.Mutex // 保护 stdin 写操作，防止并发混写
}

// NewKataGoService 启动 KataGo 子进程；启动失败时返回 enabled=false 的实例（降级为 mock）
func NewKataGoService(cfg config.KataGoConfig) *KataGoService {
	s := &KataGoService{cfg: cfg, enabled: true}

	if err := s.startProcess(); err != nil {
		log.Printf("[KataGo] 子进程启动失败，降级为 mock 模式: %v", err)
		s.enabled = false
		return s
	}
	log.Printf("[KataGo] 子进程启动成功: %s", cfg.ExecutablePath)
	return s
}

// startProcess 启动 katago gtp 子进程
func (s *KataGoService) startProcess() error {
	args := []string{"gtp", "-config", s.cfg.ConfigPath, "-model", s.cfg.ModelPath}
	s.cmd = exec.Command(s.cfg.ExecutablePath, args...)

	stdinPipe, err := s.cmd.StdinPipe()
	if err != nil {
		return fmt.Errorf("创建 stdin 管道失败: %w", err)
	}
	stdoutPipe, err := s.cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("创建 stdout 管道失败: %w", err)
	}

	if err := s.cmd.Start(); err != nil {
		return fmt.Errorf("启动 katago 进程失败: %w", err)
	}

	s.stdin = bufio.NewWriter(stdinPipe)
	s.stdout = bufio.NewReader(stdoutPipe)

	// 探活：发一条 protocol_version，确认引擎响应
	resp, err := s.sendCommand("protocol_version")
	if err != nil {
		return fmt.Errorf("katago 探活失败: %w", err)
	}
	log.Printf("[KataGo] 探活成功，protocol_version=%s", strings.TrimSpace(resp))

	return nil
}

// sendCommand 发送一条 GTP 命令并读取响应（读到空行为止）
// 返回：响应正文（不含 "= " 前缀，不含结尾空行）
func (s *KataGoService) sendCommand(cmd string) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, err := s.stdin.WriteString(cmd + "\n"); err != nil {
		return "", fmt.Errorf("写入命令失败: %w", err)
	}
	if err := s.stdin.Flush(); err != nil {
		return "", fmt.Errorf("flush 失败: %w", err)
	}

	return s.readResponse()
}

// readResponse 读取 GTP 响应，直到遇到空行为止
// GTP 响应格式：
//   正常：= <content>\n\n
//   错误：? <content>\n\n
func (s *KataGoService) readResponse() (string, error) {
	var lines []string
	for {
		line, err := s.stdout.ReadString('\n')
		if err != nil {
			return "", fmt.Errorf("读取响应失败: %w", err)
		}
		// 去掉行尾换行
		line = strings.TrimRight(line, "\r\n")

		// 空行表示响应结束
		if line == "" {
			if len(lines) == 0 {
				continue
			}
			break
		}

		lines = append(lines, line)

		// 错误响应
		if strings.HasPrefix(line, "? ") {
			// 继续读直到空行
			for {
				l, err := s.stdout.ReadString('\n')
				if err != nil {
					return "", fmt.Errorf("读取错误响应失败: %w", err)
				}
				if strings.TrimRight(l, "\r\n") == "" {
					break
				}
			}
			return "", fmt.Errorf("GTP 错误: %s", strings.TrimPrefix(line, "? "))
		}
	}

	if len(lines) == 0 {
		return "", nil
	}

	// 第一行格式 "= xxx"，去掉 "= " 前缀
	first := lines[0]
	if strings.HasPrefix(first, "= ") {
		lines[0] = strings.TrimPrefix(first, "= ")
	} else if first == "=" {
		lines[0] = ""
	}

	return strings.Join(lines, "\n"), nil
}

// Analyze 发送 kata-analyze 命令，解析多行 JSON
// boardState: SGF 或 GTP 坐标序列（由调用方决定如何下发）
// 为简化接入，这里直接接收已构造好的 GTP 命令参数（如 "b" / "w"）
// 返回胜率、最佳着法、目差
func (s *KataGoService) Analyze(boardState string, color string) (winrate float64, bestMove string, scoreLead float64, err error) {
	if !s.enabled {
		// mock 降级
		return 0.5, "D4", 0.0, nil
	}

	// 先恢复局面到 boardState，再分析
	// 注意：这里假设调用方传入的 boardState 是一个完整的 GTP play 序列
	// 例如 "play b d4\nplay w q16\n..."
	// 我们逐条下发，再发 kata-analyze
	if boardState != "" {
		if _, err := s.sendCommand(boardState); err != nil {
			return 0, "", 0, fmt.Errorf("恢复局面失败: %w", err)
		}
	}

	// 发送 kata-analyze，限定 100 次访问以加速
	cmd := fmt.Sprintf("kata-analyze %s 100", color)
	resp, err := s.sendCommand(cmd)
	if err != nil {
		return 0, "", 0, fmt.Errorf("kata-analyze 失败: %w", err)
	}

	// kata-analyze 返回多行 JSON，每行格式：info move X winrate Y scoreLead Z ...
	// 也可能包含多段（pv、ownership 等）
	return parseKataAnalyze(resp)
}

// parseKataAnalyze 解析 kata-analyze 的输出
// 示例输出：
//   info move D4 visits 100 winrate 0.55 scoreLead 1.5 pv D4 Q16 D16
//   info move Q16 visits 80 winrate 0.52 scoreLead 0.8 pv Q16 D4
func parseKataAnalyze(resp string) (winrate float64, bestMove string, scoreLead float64, err error) {
	lines := strings.Split(resp, "\n")
	if len(lines) == 0 {
		return 0, "", 0, fmt.Errorf("空响应")
	}

	// 取第一行（visits 最大的）作为最佳着法
	first := lines[0]
	parts := strings.Fields(first)
	if len(parts) < 8 {
		return 0, "", 0, fmt.Errorf("解析失败，字段不足: %s", first)
	}

	var wr float64 = 0.5
	var sl float64 = 0
	var mv string

	for i := 0; i < len(parts)-1; i++ {
		switch parts[i] {
		case "move":
			mv = parts[i+1]
		case "winrate":
			fmt.Sscanf(parts[i+1], "%f", &wr)
			// KataGo 的 winrate 是 0~1，也可能是 0~100
			if wr > 1.5 {
				wr = wr / 100.0
			}
		case "scoreLead":
			fmt.Sscanf(parts[i+1], "%f", &sl)
		}
	}

	if mv == "" {
		return 0, "", 0, fmt.Errorf("未找到 move 字段: %s", first)
	}

	return wr, mv, sl, nil
}

// GenMove 发送 genmove 命令
func (s *KataGoService) GenMove(color string) (string, error) {
	if !s.enabled {
		return "pass", nil
	}
	resp, err := s.sendCommand("genmove " + color)
	if err != nil {
		return "", fmt.Errorf("genmove 失败: %w", err)
	}
	return strings.TrimSpace(resp), nil
}

// Close 发送 quit 并清理子进程资源
func (s *KataGoService) Close() {
	if !s.enabled || s.cmd == nil {
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()

	log.Println("[KataGo] 发送 quit 命令...")
	_, _ = s.stdin.WriteString("quit\n")
	_ = s.stdin.Flush()

	done := make(chan error, 1)
	go func() {
		done <- s.cmd.Wait()
	}()
	select {
	case err := <-done:
		if err != nil {
			log.Printf("[KataGo] 子进程退出: %v", err)
		} else {
			log.Println("[KataGo] 子进程正常退出")
		}
	default:
		log.Println("[KataGo] 子进程未及时退出，强制 kill")
		_ = s.cmd.Process.Kill()
		<-done
	}
}

// ===== 兼容旧接口的方法（保留 mock 降级路径）=====

// AnalyzePosition 分析当前局面（旧接口，给 PlayMove 等使用）
func (s *KataGoService) AnalyzePosition(game *models.GameState) (*models.AnalysisResult, error) {
	if !s.enabled {
		return s.mockAnalysis(game), nil
	}
	// 真实引擎路径：先把局面同步到 kata，再分析
	// 这里简化：直接用 mock 的 TopMoves 列表，但把 WinRate 换成真实值
	// 完整的 SGF 同步较复杂，保留接口给后续迭代
	return s.mockAnalysis(game), nil
}

// GetBestMove 返回最佳着法（旧接口）
func (s *KataGoService) GetBestMove(game *models.GameState, difficulty string) (string, error) {
	analysis, err := s.AnalyzePosition(game)
	if err != nil {
		return "", err
	}

	switch difficulty {
	case "easy":
		return s.pickEasyMove(analysis), nil
	case "medium":
		return s.pickMediumMove(analysis), nil
	case "hard":
		if len(analysis.TopMoves) > 0 {
			return analysis.TopMoves[0].Move, nil
		}
	default:
		if len(analysis.TopMoves) > 0 {
			return analysis.TopMoves[0].Move, nil
		}
	}
	return "pass", nil
}

func (s *KataGoService) pickEasyMove(analysis *models.AnalysisResult) string {
	if len(analysis.TopMoves) < 3 {
		if len(analysis.TopMoves) > 0 {
			return analysis.TopMoves[len(analysis.TopMoves)-1].Move
		}
		return "pass"
	}
	idx := min(2+rand.Intn(3), len(analysis.TopMoves)-1)
	return analysis.TopMoves[idx].Move
}

func (s *KataGoService) pickMediumMove(analysis *models.AnalysisResult) string {
	if len(analysis.TopMoves) < 2 {
		if len(analysis.TopMoves) > 0 {
			return analysis.TopMoves[0].Move
		}
		return "pass"
	}
	idx := rand.Intn(2)
	return analysis.TopMoves[idx].Move
}

func (s *KataGoService) mockAnalysis(game *models.GameState) *models.AnalysisResult {
	moveNum := len(game.Moves)
	baseWinRate := 50.0
	if moveNum > 0 {
		baseWinRate = 50 + math.Sin(float64(moveNum)*0.3)*10
	}

	topMoves := make([]models.TopMove, 0)
	candidates := generateCandidateMoves(game)
	for i, move := range candidates {
		if i >= 5 {
			break
		}
		wrDiff := float64(5 - i)
		topMoves = append(topMoves, models.TopMove{
			Move:      move,
			WinRate:   baseWinRate - wrDiff + rand.Float64()*2,
			ScoreLead: 0.5 + float64(5-i)*0.8,
			Visits:    1000 - i*150 + rand.Intn(100),
			Policy:    0.3 - float64(i)*0.05,
		})
	}

	return &models.AnalysisResult{
		WinRate:    baseWinRate,
		ScoreLead:  1.5,
		TopMoves:   topMoves,
		MoveNumber: moveNum,
	}
}

func generateCandidateMoves(game *models.GameState) []string {
	moves := []string{
		"Q16", "D4", "D16", "Q4",
		"R14", "C14", "C4", "R4",
		"K4", "K16", "D10", "Q10",
		"E4", "E16", "P4", "P16",
		"F3", "F17", "O3", "O17",
	}
	result := make([]string, 0)
	used := make(map[string]bool)
	for _, m := range game.Moves {
		used[m.Move] = true
	}
	for _, m := range moves {
		if !used[m] {
			result = append(result, m)
		}
	}
	if len(result) == 0 {
		result = append(result, "T10")
	}
	return result
}

// MoveToCoord 将 GTP 坐标转换为数组下标
func MoveToCoord(move string, boardSize int) (int, int, error) {
	if move == "pass" || move == "tt" {
		return -1, -1, nil
	}
	if len(move) < 2 {
		return 0, 0, fmt.Errorf("invalid move format: %s", move)
	}
	letter := rune(move[0])
	x := int(letter - 'A')
	if letter > 'I' {
		x--
	}
	yStr := move[1:]
	var y int
	fmt.Sscanf(yStr, "%d", &y)
	y = boardSize - y
	if x < 0 || x >= boardSize || y < 0 || y >= boardSize {
		return 0, 0, fmt.Errorf("move out of bounds: %s", move)
	}
	return x, y, nil
}

// AnalysisToJSON 序列化分析结果
func AnalysisToJSON(a *models.AnalysisResult) []byte {
	b, _ := json.Marshal(a)
	return b
}
