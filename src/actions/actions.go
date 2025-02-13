package actions

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/davidclarafigueiredo/SaleNotifier/connect"
	"github.com/davidclarafigueiredo/SaleNotifier/handler"
	"github.com/davidclarafigueiredo/SaleNotifier/scraper"
	"github.com/shopspring/decimal"
)

func Contains(list []string, item string) bool {
	for _, v := range list {
		if v == item {
			return true
		}
	}
	return false
}

func ReturnArrayFromWishlist(column int) []string {
	fileName := "data/wishlist"
	separator := "; "

	readFile, err := os.Open(fileName)
	if err != nil && !os.IsNotExist(err) {
		log.Fatal("Error opening output file for reading:", err)
	}
	defer readFile.Close()

	var entriesArray []string
	if err == nil { // Only scan if file exists
		readFileScanner := bufio.NewScanner(readFile)
		for readFileScanner.Scan() {
			line := readFileScanner.Text()
			parts := strings.Split(line, separator)
			if len(parts) > 0 {
				entrie := parts[column] // First value (NSUID)
				entriesArray = append(entriesArray, entrie)
			}
		}

		if err := readFileScanner.Err(); err != nil {
			log.Fatal("Error reading output file:", err)
		}
	}

	return entriesArray

}

func WriteEntrieToWishlist(url string, nsuidEntries []string) bool {
	outputFileName := "data/wishlist"
	nsuid := scraper.GetNSUID(url)
	separator := "; "

	// Open or create the output file
	outputFile, err := os.OpenFile(outputFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer outputFile.Close()

	if Contains(nsuidEntries, nsuid) {
		return false
	}
	gameTitle := scraper.GetGameTitle(url)
	apiUrl := os.Getenv("REQUEST") + nsuid

	regularPrice := scraper.GetPrice(url)
	discountedPrice := handler.GetPrice(connect.Connect(apiUrl))

	isDiscounted := ComparePrice(url, apiUrl)

	entry := fmt.Sprintf("%s%s%s%s%s%s%s%s%t%s%s%s%s\n",
		nsuid, separator,
		url, separator,
		apiUrl, separator,
		gameTitle, separator,
		isDiscounted, separator,
		regularPrice, separator,
		discountedPrice,
	)

	_, err = outputFile.WriteString(entry)
	if err != nil {
		log.Fatal("Error writing to file:", err)
	}
	return true
}

func CreateWishlistEntries() {
	sourceFileName := "data/import"

	nsuidEntries := ReturnArrayFromWishlist(0)

	// Open the source file for reading
	sourceFile, err := os.Open(sourceFileName)
	if err != nil {
		log.Fatal("Error opening file:", err)
	}
	defer sourceFile.Close() // Ensure file is closed when done

	// Create a scanner to read the file line by line
	sourceFileScanner := bufio.NewScanner(sourceFile)
	var urls []string

	// Read and print each line
	for sourceFileScanner.Scan() {
		urls = append(urls, sourceFileScanner.Text())
	}

	// Check for errors while scanning
	if err := sourceFileScanner.Err(); err != nil {
		log.Fatal("Error reading file:", err)
	}

	// Write to file
	for _, url := range urls {
		WriteEntrieToWishlist(url, nsuidEntries)
	}
}

func UpdateWishlistEntries() {
	urls := ReturnArrayFromWishlist(1)

	fileName := "data/wishlist"

	// Create (or overwrite) the file
	file, err := os.Create(fileName)
	if err != nil {
		log.Fatal("Error creating file:", err)
	}
	defer file.Close()

	for _, url := range urls {
		WriteEntrieToWishlist(url, []string{})
	}

}

func SaleChecker() {
	oldOnSale := ReturnArrayFromWishlist(4)

	UpdateWishlistEntries()

	newOnSale := ReturnArrayFromWishlist(4)

	apiUrls := ReturnArrayFromWishlist(2)
	urls := ReturnArrayFromWishlist(1)

	for i := 0; i < len(oldOnSale); i++ {
		if oldOnSale[i] == "false" && newOnSale[i] == "true" {
			fmt.Println(scraper.GetGameTitle(urls[i]) + " is now on sale. Get it for " + handler.GetFormPrice(connect.Connect(apiUrls[i])) + "!")
		}
	}

}

func ComparePrice(url string, apiUrl string) bool {

	price, _ := decimal.NewFromString(handler.GetPrice(connect.Connect(apiUrl)))
	discountPrice, _ := decimal.NewFromString(scraper.GetPrice(url))

	if !price.Equal(discountPrice) {
		fmt.Println("Price: ", price)
		fmt.Println("Discount Price: ", discountPrice)
		// fmt.Printf("%s is on sale for %s", scraper.GetGameTitle(url), handler.GetFormPrice(connect.Connect(apiUrl)))
		return true
	}
	return false
}
