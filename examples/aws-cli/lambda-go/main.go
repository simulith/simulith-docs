package main

import (
	"encoding/json"
	"io"
	"os"
)

// Minimal provided.al2023 bootstrap: event JSON on stdin, response JSON on stdout.
// Pattern: https://docs.aws.amazon.com/lambda/latest/dg/golang-package.html
func main() {
	var event map[string]any
	raw, err := io.ReadAll(os.Stdin)
	if err == nil && len(raw) > 0 {
		_ = json.Unmarshal(raw, &event)
	}
	greeting := os.Getenv("GREETING")
	if greeting == "" {
		greeting = "hello-from-go"
	}
	_ = json.NewEncoder(os.Stdout).Encode(map[string]any{
		"greeting": greeting,
		"echo":     event,
	})
}
