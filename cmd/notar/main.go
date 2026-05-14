package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

var (
	version = "dev"
	commit  = "none"
	date    = "unknown"
)

func main() {
	fmt.Printf("notar %s (commit %s, built %s)\n", version, commit, date)

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig
}
