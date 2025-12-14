package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"
)

type Response struct {
	Service   string    `json:"service"`
	Message   string    `json:"message"`
	Error     string    `json:"error,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

var requestCount int
var errorCount int

func main() {
	rand.Seed(time.Now().UnixNano())

	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/generate-error", generateErrorHandler)
	http.HandleFunc("/random-error", randomErrorHandler)
	http.HandleFunc("/timeout", timeoutHandler)
	http.HandleFunc("/metrics", metricsHandler)

	port := ":4000"
	log.Printf("Error generator service starting on port %s", port)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal(err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Service:   "error-generator",
		Message:   "healthy",
		Timestamp: time.Now(),
	})
}

func generateErrorHandler(w http.ResponseWriter, r *http.Request) {
	requestCount++
	errorCount++

	errorType := r.URL.Query().Get("type")
	if errorType == "" {
		errorType = "generic"
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusInternalServerError)

	json.NewEncoder(w).Encode(Response{
		Service:   "error-generator",
		Error:     fmt.Sprintf("Generated error: %s", errorType),
		Message:   "Error generated successfully",
		Timestamp: time.Now(),
	})
}

func randomErrorHandler(w http.ResponseWriter, r *http.Request) {
	requestCount++

	// 30% chance of error
	if rand.Float32() < 0.3 {
		errorCount++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(Response{
			Service:   "error-generator",
			Error:     "Random error occurred",
			Timestamp: time.Now(),
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Service:   "error-generator",
		Message:   "Request successful",
		Timestamp: time.Now(),
	})
}

func timeoutHandler(w http.ResponseWriter, r *http.Request) {
	requestCount++
	errorCount++

	// Simulate a long-running request that times out
	time.Sleep(10 * time.Second)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Service:   "error-generator",
		Message:   "This should have timed out",
		Timestamp: time.Now(),
	})
}

func metricsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"service":      "error-generator",
		"totalRequests": requestCount,
		"errorCount":    errorCount,
		"errorRate":     float64(errorCount) / float64(requestCount) * 100,
		"timestamp":     time.Now(),
	})
}

