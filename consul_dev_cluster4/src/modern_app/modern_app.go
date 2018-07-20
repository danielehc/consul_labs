package main

import (
	"fmt"
	"strings"
	"strconv"
	"github.com/hashicorp/consul/api"
	"github.com/go-redis/redis"
	"time"
)

func main() {
	//~ fmt.Printf("hello, world\n")
	
	var consulClient *api.Client
	
	consulClient, err := api.NewClient(api.DefaultConfig())
	
	if err !=nil {
		fmt.Printf("Failed to contact consul. \n", err)
		return
	}
	
	consulCatalog := consulClient.Catalog()
	
	var serviceDetail strings.Builder
	
	redisService, _, err := consulCatalog.Service("redis", "", nil)
	if err != nil {
		fmt.Printf("Failed to discover Redis Service. \n", err)
		return
	}
	
	if redisService == nil {
		
		fmt.Printf("Service is null. \n")
		return
		
	} else {
		
		fmt.Printf("Service is not null. \n")
		
		if (len(redisService) == 0){
			fmt.Printf("...Still there is no service for what you asked. \n")
			return
			
		} else {
				
			serviceDetail.WriteString(string(redisService[0].Address))
			serviceDetail.WriteString(":")
			//~ https://golang.org/pkg/strconv/
			serviceDetail.WriteString(strconv.Itoa(redisService[0].ServicePort))
		 
			fmt.Printf(serviceDetail.String())
			fmt.Printf("\n")		
		}
	}
	
	//~ https://github.com/go-redis/redis/blob/master/example_test.go
	client := redis.NewClient(&redis.Options{
		Addr:     serviceDetail.String(),
		Password: "", // no password set
		DB:       0,  // use default DB
	})

	//~ pong, err := client.Ping().Result()
	//~ fmt.Println(pong, err)
	for {
			result, err := client.Incr("counter_modern").Result()
			if err != nil {
				panic(err)
			}

		fmt.Println(result)
		time.Sleep(5 * time.Second)
	}
	
	
}
