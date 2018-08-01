package main

import (
	"fmt"
	"strings"
	"strconv"
	"github.com/hashicorp/consul/api"
	"github.com/go-redis/redis"
	"html/template"
	"flag"
	"net/http"
	"regexp"
	//~ "log"
	//~ "errors"
)

var targetPort string
var targetIP string

var templates *template.Template
var healthStatus string

var serviceUrl string
var redisClient *redis.Client

func main() {
	
	// Collect info for webserver
	
	portPtr := flag.Int("port", 8080, "Default's to port 8080. Use -port=nnnn to use listen on an alternate port.")
	ipPtr := flag.String("ip", "0.0.0.0", "Default's to 0.0.0.0")
	flag.Parse()
	targetPort = strconv.Itoa(*portPtr)
	targetIP = *ipPtr
	
	var portDetail strings.Builder
	portDetail.WriteString(targetIP)
	portDetail.WriteString(":")
	portDetail.WriteString(targetPort)
	fmt.Printf("URL: %s \n", portDetail.String())
	
	// Define paths
	
	http.HandleFunc("/health/", healthHandler)
    http.HandleFunc("/", indexHandler)
	
	// Register service with Consul
	
	// Start Web Sever
	http.ListenAndServe(portDetail.String(), nil)
}


func indexHandler(w http.ResponseWriter, r *http.Request) {
  var validPath = regexp.MustCompile("^[/]$")
		
	m := validPath.FindStringSubmatch(r.URL.Path)
	
	if m == nil {
			http.NotFound(w, r)
			//~ fmt.Fprintf(w, "Something weird happened!\n")
	} else {
		  
		var consulClient *api.Client
		
		consulClient, err := api.NewClient(api.DefaultConfig())
		
		if err !=nil {
			
			http.Error(w, "0", http.StatusInternalServerError)
			fmt.Printf("Failed to contact consul: %s \n", err)
			healthStatus = "KO"
			return
		}
		
		consulCatalog := consulClient.Catalog()
		
		var serviceDetail strings.Builder
		
		redisService, _, err := consulCatalog.Service("redis", "", nil)
		if err != nil {
			http.Error(w, "0", http.StatusInternalServerError)
			fmt.Printf("Failed to discover Redis Service: %s \n", err)
			healthStatus = "KO"
			return
		}
		
		if redisService == nil {
			
			http.Error(w, "0", http.StatusInternalServerError)
			fmt.Printf("Service is null. \n")
			healthStatus = "KO"
			return
			
		} else {
			
			fmt.Printf("Service is not null. \n")
			
			if (len(redisService) == 0){
				http.Error(w, "0", http.StatusInternalServerError)
				fmt.Printf("...Still there is no service for what you asked. \n")
				healthStatus = "KO"
				return
				
			} else {
					
				serviceDetail.WriteString(string(redisService[0].Address))
				serviceDetail.WriteString(":")
				//~ https://golang.org/pkg/strconv/
				serviceDetail.WriteString(strconv.Itoa(redisService[0].ServicePort))
			 
				fmt.Printf("Found Redis service at: %s \n", serviceDetail.String())	
				healthStatus = "OK"
			}
		}
		
		//~ https://github.com/go-redis/redis/blob/master/example_test.go
		client := redis.NewClient(&redis.Options{
			Addr:     serviceDetail.String(),
			Password: "", // no password set
			DB:       0,  // use default DB
		})
		
		result, err := client.Incr("modern_app").Result()
		if err != nil {
			http.Error(w, "0", http.StatusInternalServerError)
			return
		}    
		
		fmt.Fprintf(w, "%d", result)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request){
	var validPath = regexp.MustCompile("^/(health)/$")
		
	m := validPath.FindStringSubmatch(r.URL.Path)
	
	if m == nil {
			http.NotFound(w, r)
			//~ fmt.Fprintf(w, "Something weird happened!\n")
	} else {
		fmt.Fprintf(w, "Status is %s!\n", healthStatus)
		fmt.Printf("Failed to discover Redis Service. \n")	
	}    	
}
