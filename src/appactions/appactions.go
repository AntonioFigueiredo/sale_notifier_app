package appactions

import (
	"github.com/davidclarafigueiredo/SaleNotifier/actions"
	"github.com/davidclarafigueiredo/SaleNotifier/connect"
	"github.com/davidclarafigueiredo/SaleNotifier/handler"
	"github.com/davidclarafigueiredo/SaleNotifier/scraper"
)

//export GetInformation
func GetInformation(url string) string {
	nsuid := scraper.GetNSUID(url)
	apiUrl := "https://api.ec.nintendo.com/v1/price?country=DE&lang=de&ids=" + nsuid

	gameTitle := scraper.GetGameTitle(url)
	regularPrice := scraper.GetPrice(url)
	discountedPrice := handler.GetPrice(connect.Connect(apiUrl))

	isDiscounted := "not on sale"
	if actions.ComparePrice(url, apiUrl) {
		isDiscounted = "on sale"
	}

	return gameTitle + " ;" + regularPrice + " ;" + discountedPrice + " ;" + isDiscounted

}
