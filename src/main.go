package main

import (
	"fmt"

	"github.com/davidclarafigueiredo/SaleNotifier/appactions"
	"github.com/davidclarafigueiredo/SaleNotifier/config"
)

// type GameData struct {
// 	NsuID      int    `json:"nsuID"`
// 	Url        string `json:"url"`
// 	ApiUrl     string `json:"apiUrl"`
// 	GameTitle  string `json:"gameTitle"`
// 	SaleStatus string `json:"saleStatus"`
// 	Price      string `json:"price"`
// }

// func main() {
// 	config.Init()
// 	//fmt.Printf("%s\n", handler.GetPrice(connect.Connect()))
// 	//handler.SendMail()

// 	// actions.CreateWishlistEntries()
// 	// actions.SaleChecker()

// 	// Assuming you've scraped these values
// 	nsuid := 70010000033557
// 	url := "https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Download-Software/Disney-Dreamlight-Valley-2232608.html"
// 	apiUrl := "https://api.ec.nintendo.com/v1/price?country=DE&lang=de&ids=70010000033557"
// 	gameTitle := "Disney Dreamlight Valley"
// 	saleStatus := "on sale"
// 	price := "29,99 €"

// 	games := []GameData{
// 		{
// 			NsuID:      nsuid,
// 			Url:        url,
// 			ApiUrl:     apiUrl,
// 			GameTitle:  gameTitle,
// 			SaleStatus: saleStatus,
// 			Price:      price,
// 		},
// 		{
// 			NsuID:      70010000044643,
// 			Url:        "https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Download-Software/No-Man-s-Sky-2169216.html",
// 			ApiUrl:     "https://api.ec.nintendo.com/v1/price?country=DE&lang=de&ids=70010000044643",
// 			GameTitle:  "No Man's Sky",
// 			SaleStatus: "on sale",
// 			Price:      "19,99 €",
// 		},
// 		{
// 			NsuID:      70010000084603,
// 			Url:        "https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Spiele/Donkey-Kong-Country-Returns-HD-2590475.html",
// 			ApiUrl:     "https://api.ec.nintendo.com/v1/price?country=DE&lang=de&ids=70010000084603",
// 			GameTitle:  "Donkey Kong Country Returns HD",
// 			SaleStatus: "not on sale",
// 			Price:      "59,99 €",
// 		},
// 		{
// 			NsuID:      70010000041431,
// 			Url:        "https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Spiele/Sid-Meier-s-Civilization-VII-2637632.html",
// 			ApiUrl:     "https://api.ec.nintendo.com/v1/price?country=DE&lang=de&ids=70010000041431",
// 			GameTitle:  "Sid Meier's Civilization® VII",
// 			SaleStatus: "not on sale",
// 			Price:      "59,99 €",
// 		},
// 	}

// 	// Get the parent directory of the Go program
// 	dir, err := os.Getwd()
// 	if err != nil {
// 		log.Fatal("Error getting current working directory:", err)
// 	}

// 	// Get the parent directory by going one level up
// 	parentDir := filepath.Dir(dir)

// 	// Save the file in the parent directory
// 	filePath := filepath.Join(parentDir, "game_data.json") // This stores the file in the parent directory

// 	// Convert game data to JSON
// 	gameDataJSON, err := json.Marshal(games)
// 	if err != nil {
// 		log.Fatal("Error marshalling game data:", err)
// 	}

// 	// Write JSON to the parent directory
// 	err = os.WriteFile(filePath, gameDataJSON, 0644)
// 	if err != nil {
// 		log.Fatal("Error writing to file:", err)
// 	}

// 	fmt.Println("Game data saved!")
// }

func main() {
	config.Init()
	fmt.Println(appactions.GetInformation("https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Spiele/Donkey-Kong-Country-Returns-HD-2590475.html"))
}
