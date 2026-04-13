package main

import (
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	memoryThresholdMB        = 12.0
	thresholdDurationSeconds = 90 * time.Second
	memoryCheckInterval      = 5 * time.Second
)

var (
	memoryOverThresholdStart time.Time
	memoryMu                 sync.Mutex
)

func getMemoryUsageMB() float64 {
	data, err := os.ReadFile("/proc/self/status")
	if err != nil {
		log.Printf("Error reading memory: %v", err)
		return 0
	}

	for _, line := range strings.Split(string(data), "\n") {
		if strings.HasPrefix(line, "VmRSS:") {
			fields := strings.Fields(line)
			if len(fields) < 2 {
				return 0
			}

			memoryKB, err := strconv.Atoi(fields[1])
			if err != nil {
				log.Printf("Error parsing memory usage: %v", err)
				return 0
			}

			return float64(memoryKB) / 1024.0
		}
	}

	return 0
}

func monitorMemory() {
	ticker := time.NewTicker(memoryCheckInterval)
	defer ticker.Stop()

	for {
		func() {
			defer func() {
				if r := recover(); r != nil {
					log.Printf("Memory monitoring error: %v", r)
				}
			}()

			memoryMB := getMemoryUsageMB()

			memoryMu.Lock()
			defer memoryMu.Unlock()

			if memoryMB > memoryThresholdMB {
				if memoryOverThresholdStart.IsZero() {
					memoryOverThresholdStart = time.Now()
					log.Printf("Memory usage %.2fMB exceeds threshold %.0fMB", memoryMB, memoryThresholdMB)
					return
				}

				duration := time.Since(memoryOverThresholdStart)
				if duration >= thresholdDurationSeconds {
					log.Printf("Memory over threshold for %.0fs, running full GC", duration.Seconds())
					runtime.GC()
					memoryAfter := getMemoryUsageMB()
					log.Printf("GC complete: %.2fMB -> %.2fMB", memoryMB, memoryAfter)
					memoryOverThresholdStart = time.Time{}
				}
			} else {
				if !memoryOverThresholdStart.IsZero() {
					log.Printf("Memory usage %.2fMB back below threshold", memoryMB)
				}
				memoryOverThresholdStart = time.Time{}
			}
		}()

		<-ticker.C
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	x := 0.0
	for i := 0; i < 10000000; i++ {
		x += math.Sqrt(float64(i + 1))
	}

	_ = x

	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("OK!"))
}

func main() {
	go monitorMemory()
	fmt.Printf("Memory monitor started (threshold: %.0fMB for %.0fs)\n", memoryThresholdMB, thresholdDurationSeconds.Seconds())

	http.HandleFunc("/", handler)
	fmt.Println("Server starting on port 80")

	server := &http.Server{
		Addr:              "0.0.0.0:80",
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Fatal(server.ListenAndServe())
}
