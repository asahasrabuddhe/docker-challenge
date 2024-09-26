package main

import (
	"fmt"
	"log"
	"os"
)

func main() {
	config, err := os.ReadFile("/go/bin/config.yaml")
	if err != nil {
		log.Println(err)
		os.Exit(1)
	}

	fmt.Println("config", string(config))

	fmt.Println("Hello, World")
}
